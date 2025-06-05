import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looply/VideoPage/videopage.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

// Assuming ThemeProvider is defined in video_page.dart (artifact_id: a98dbebc-7ac7-4096-a3b1-6ceac1d3c377)
// import 'package:looply/VideoPage/video_page.dart';

// Custom metadata class to include thumbnail
class VideoMetadata {
  final VideoData? videoData;
  final Uint8List? thumbnailData;

  VideoMetadata({this.videoData, this.thumbnailData});
}

class VideoPickerPage extends StatefulWidget {
  final String folderName;
  final List<String> videoPaths;

  const VideoPickerPage({
    Key? key,
    required this.folderName,
    required this.videoPaths,
  }) : super(key: key);

  @override
  _VideoPickerPageState createState() => _VideoPickerPageState();
}

class _VideoPickerPageState extends State<VideoPickerPage> {
  final FlutterVideoInfo _flutterVideoInfo = FlutterVideoInfo();
  final Map<String, VideoMetadata> _videoMeta = {};
  bool _isLoading = true;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  List<String> filteredVideoPaths = [];
  String _sortByOption = 'Sort By';

  @override
  void initState() {
    super.initState();
    filteredVideoPaths = widget.videoPaths;
    searchController.addListener(_filterVideos);
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      for (final path in widget.videoPaths) {
        final info = await _flutterVideoInfo.getVideoInfo(path);
        final thumbnail = await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 100,
          quality: 75,
        );
        _videoMeta[path] = VideoMetadata(
          videoData: info,
          thumbnailData: thumbnail,
        );
      }
      setState(() {
        _isLoading = false;
        _sortVideos();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video metadata: $e')),
      );
    }
  }

  void _filterVideos() {
    setState(() {
      final query = searchController.text.toLowerCase().trim();
      filteredVideoPaths = widget.videoPaths.where((path) {
        final fileName = p.basename(path).toLowerCase();
        return fileName.contains(query);
      }).toList();
      _sortVideos();
    });
  }

  void _sortVideos() {
    switch (_sortByOption) {
      case 'Sort By Name A-Z':
        filteredVideoPaths.sort((a, b) => p.basename(a).toLowerCase().compareTo(p.basename(b).toLowerCase()));
        break;
      case 'Sort By Name Z-A':
        filteredVideoPaths.sort((a, b) => p.basename(b).toLowerCase().compareTo(p.basename(a).toLowerCase()));
        break;
      case 'Sort By Duration Asc':
        filteredVideoPaths.sort((a, b) {
          final durationA = _videoMeta[a]?.videoData?.duration?.toInt() ?? 0;
          final durationB = _videoMeta[b]?.videoData?.duration?.toInt() ?? 0;
          return durationA.compareTo(durationB);
        });
        break;
      case 'Sort By Duration Desc':
        filteredVideoPaths.sort((a, b) {
          final durationA = _videoMeta[a]?.videoData?.duration?.toInt() ?? 0;
          final durationB = _videoMeta[b]?.videoData?.duration?.toInt() ?? 0;
          return durationB.compareTo(durationA);
        });
        break;
      case 'Sort By Size Asc':
        filteredVideoPaths.sort((a, b) {
          final sizeA = _videoMeta[a]?.videoData?.filesize ?? 0;
          final sizeB = _videoMeta[b]?.videoData?.filesize ?? 0;
          return sizeA.compareTo(sizeB);
        });
        break;
      case 'Sort By Size Desc':
        filteredVideoPaths.sort((a, b) {
          final sizeA = _videoMeta[a]?.videoData?.filesize ?? 0;
          final sizeB = _videoMeta[b]?.videoData?.filesize ?? 0;
          return sizeB.compareTo(sizeA);
        });
        break;
    }
  }

  String _formatDuration(int? millis) {
    if (millis == null) return '--:--';
    final duration = Duration(milliseconds: millis);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '--';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  void _showSortDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _searchFocusNode.unfocus();
            Navigator.pop(context);
          },
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDarkMode = themeProvider.isDarkMode;
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sort by',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OptionMenu(
                      text: 'Name A-Z',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Name A-Z';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                    OptionMenu(
                      text: 'Name Z-A',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Name Z-A';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                    OptionMenu(
                      text: 'Duration Asc',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Duration Asc';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                    OptionMenu(
                      text: 'Duration Desc',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Duration Desc';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                    OptionMenu(
                      text: 'Size Asc',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Size Asc';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                    OptionMenu(
                      text: 'Size Desc',
                      callbackAction: () {
                        setState(() {
                          _sortByOption = 'Sort By Size Desc';
                          _sortVideos();
                        });
                        _searchFocusNode.unfocus();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _searchFocusNode.unfocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    ));

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.grey.shade900, Colors.black]
                  : [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            top: true,
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.deepPurple : Colors.blueAccent,
                ),
              ),
            )
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Text(
                    widget.folderName,
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: isDarkMode ? Colors.white : Colors.blue.shade900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: IOSSearchBar(
                          controller: searchController,
                          focusNode: _searchFocusNode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSortDrawer(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                _sortByOption,
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  thickness: 1,
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                Expanded(
                  child: filteredVideoPaths.isEmpty
                      ? Center(
                    child: Text(
                      'No videos found',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  )
                      : AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredVideoPaths.length,
                      itemBuilder: (context, index) {
                        final path = filteredVideoPaths[index];
                        final meta = _videoMeta[path];

                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          columnCount: 3,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tapped: ${p.basename(path)}')),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: meta?.thumbnailData != null
                                            ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.memory(
                                            meta!.thumbnailData!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.videocam,
                                              size: 48,
                                              color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade600,
                                            ),
                                          ),
                                        )
                                            : Icon(
                                          Icons.videocam,
                                          size: 48,
                                          color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade600,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.basename(path),
                                              style: GoogleFonts.notoSans(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: isDarkMode ? Colors.white : Colors.blue.shade900,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDuration(meta?.videoData?.duration?.toInt()),
                                              style: GoogleFonts.notoSans(
                                                fontSize: 11,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              _formatBytes(meta?.videoData?.filesize),
                                              style: GoogleFonts.notoSans(
                                                fontSize: 11,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OptionMenu extends StatelessWidget {
  const OptionMenu({super.key, required this.text, required this.callbackAction});

  final String text;
  final VoidCallback callbackAction;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callbackAction,
        borderRadius: BorderRadius.circular(12),
        splashColor: (isDarkMode ? Colors.deepPurple : Colors.blue).withOpacity(0.3),
        highlightColor: (isDarkMode ? Colors.deepPurple : Colors.blue).withOpacity(0.1),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IOSSearchBar extends StatefulWidget {
  const IOSSearchBar({super.key, required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<IOSSearchBar> createState() => _IOSSearchBarState();
}

class _IOSSearchBarState extends State<IOSSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        cursorColor: isDarkMode ? Colors.deepPurple : Colors.blueAccent,
        style: GoogleFonts.notoSans(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search videos',
          hintStyle: GoogleFonts.notoSans(
            fontSize: 16,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            onPressed: () {
              widget.controller.clear();
              FocusScope.of(context).unfocus();
            },
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}