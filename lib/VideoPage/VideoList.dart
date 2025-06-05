import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';

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
  final Map<String, VideoData> _videoMeta = {};
  bool _isLoading = true;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  List<String> filteredVideoPaths = [];
  String _sortByOption = 'Sort By';

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    filteredVideoPaths = widget.videoPaths;
    searchController.addListener(_filterVideos);
  }

  Future<void> _loadMetadata() async {
    for (final path in widget.videoPaths) {
      final info = await _flutterVideoInfo.getVideoInfo(path);
      if (info != null) {
        _videoMeta[path] = info;
      }
    }
    setState(() {
      _isLoading = false;
      _sortVideos(); // Initial sort
    });
  }

  void _filterVideos() {
    setState(() {
      final query = searchController.text.toLowerCase().trim();
      filteredVideoPaths = widget.videoPaths.where((path) {
        final fileName = basename(path).toLowerCase();
        return fileName.contains(query);
      }).toList();
      _sortVideos();
    });
  }

  void _sortVideos() {
    switch (_sortByOption) {
      case 'Sort By Name A-Z':
        filteredVideoPaths.sort((a, b) => basename(a).toLowerCase().compareTo(basename(b).toLowerCase()));
        break;
      case 'Sort By Name Z-A':
        filteredVideoPaths.sort((a, b) => basename(b).toLowerCase().compareTo(basename(a).toLowerCase()));
        break;
      case 'Sort By Duration Asc':
        filteredVideoPaths.sort((a, b) {
          final durationA = _videoMeta[a]?.duration?.toInt() ?? 0;
          final durationB = _videoMeta[b]?.duration?.toInt() ?? 0;
          return durationA.compareTo(durationB);
        });
        break;
      case 'Sort By Duration Desc':
        filteredVideoPaths.sort((a, b) {
          final durationA = _videoMeta[a]?.duration?.toInt() ?? 0;
          final durationB = _videoMeta[b]?.duration?.toInt() ?? 0;
          return durationB.compareTo(durationA);
        });
        break;
      case 'Sort By Size Asc':
        filteredVideoPaths.sort((a, b) {
          final sizeA = _videoMeta[a]?.filesize ?? 0;
          final sizeB = _videoMeta[b]?.filesize ?? 0;
          return sizeA.compareTo(sizeB);
        });
        break;
      case 'Sort By Size Desc':
        filteredVideoPaths.sort((a, b) {
          final sizeA = _videoMeta[a]?.filesize ?? 0;
          final sizeB = _videoMeta[b]?.filesize ?? 0;
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

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showSortDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _searchFocusNode.unfocus(); // Unfocus when tapping outside
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  border: Border.all(
                    color: Colors.white24,
                    width: 0.5,
                  ),
                ),
                child:Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sort by',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
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
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Ensure the search bar is unfocused when the drawer closes
      _searchFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            top: true,
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
                      fontSize: 22,
                      color: Colors.black,
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
                            color: Colors.white,
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
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredVideoPaths.isEmpty
                      ? Center(
                    child: Text(
                      'No videos found',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                      : GridView.builder(
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
                      final info = _videoMeta[path];

                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tapped: ${basename(path)}')),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 48,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                basename(path),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(info?.duration?.toInt()),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                _formatBytes(info?.filesize),
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callbackAction,
        borderRadius: BorderRadius.circular(8.0),
        splashColor: Colors.grey.withOpacity(0.3),
        highlightColor: Colors.grey.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.blue, fontSize: 16.0),
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

class _IOSSearchBarState extends State<IOSSearchBar> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
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
          cursorColor: Colors.blueAccent,
          style: GoogleFonts.notoSans(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search videos',
            hintStyle: GoogleFonts.notoSans(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                widget.controller.clear();
                FocusScope.of(context).unfocus();
              },
            )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
    );
  }
}