import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looply/VideoPage/Component.dart';
import 'package:looply/VideoPage/VideoList.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'dart:async';

import 'package:looply/VideoPage/FolderList.dart';
// Placeholder imports (replace with actual paths)
// import 'package:looply/Globals.dart';
// import 'package:looply/VideoPage/Component.dart';
// import 'package:looply/VideoPage/VideoPickerPage.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(Offset tapPosition) {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}

class OptionMenu extends StatelessWidget {
  final String text;
  final VoidCallback callbackAction;

  const OptionMenu({super.key, required this.text, required this.callbackAction});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return ListTile(
      title: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      onTap: callbackAction,
    );
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with RouteAware, SingleTickerProviderStateMixin {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  Map<String, List<String>> groups = {};
  Map<String, List<String>> filteredGroups = {};
  String _sortByOption = 'Sort By';
  bool _isLoading = false;
  List<String> allVideoPath = [];
  final FlutterVideoInfo _flutterVideoInfo = FlutterVideoInfo();
  final Map<String, VideoData> _videoMeta = {};
  late AnimationController _animationController;
  late Animation<double> _explosionAnimation;
  Offset? _tapPosition;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _filterGroups);
    });
    _fetchAllVideoPaths();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchFocusNode.unfocus();
    // routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // routeObserver.unsubscribe(this);
    _searchFocusNode.dispose();
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllVideoPaths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videoFolders = await PhotoManager.getAssetPathList(type: RequestType.video);
      List<AssetEntity> allVideos = [];
      for (final folder in videoFolders) {
        int page = 0;
        const pageSize = 500;
        while (true) {
          final videos = await folder.getAssetListPaged(page: page, size: pageSize);
          if (videos.isEmpty) break;
          allVideos.addAll(videos);
          page++;
        }
      }

      allVideoPath = (await Future.wait(allVideos.map((v) => getVideoPath(v)))).where((path) => path.isNotEmpty).toList();
      groups.clear();
      _videoMeta.clear();
      for (var path in allVideoPath) {
        final info = await _flutterVideoInfo.getVideoInfo(path);
        if (info != null) {
          _videoMeta[path] = info;
        }
        final dirName = dirname(path);
        groups.putIfAbsent(dirName, () => []).add(path);
      }

      filteredGroups.addAll(groups);
      _filterGroups();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Text('Error fetching videos: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchAllVideoPaths,
          ),
        ),
      );
    }
  }

  Future<String> getVideoPath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path ?? '';
  }

  void _filterGroups() {
    final query = searchController.text.toLowerCase().trim();
    filteredGroups.clear();

    if (query.isEmpty) {
      filteredGroups.addAll(groups);
    } else {
      groups.forEach((key, value) {
        final folderName = basename(key).toLowerCase();
        if (folderName.contains(query)) {
          filteredGroups[key] = value;
        }
      });
    }

    final entries = filteredGroups.entries.toList();

    switch (_sortByOption) {
      case 'Sort By Name A-Z':
        entries.sort((a, b) => basename(a.key).toLowerCase().compareTo(basename(b.key).toLowerCase()));
        break;
      case 'Sort By Name Z-A':
        entries.sort((a, b) => basename(b.key).toLowerCase().compareTo(basename(a.key).toLowerCase()));
        break;
      case 'Sort By Items 0-100':
        entries.sort((a, b) => a.value.length.compareTo(b.value.length));
        break;
      case 'Sort By Items 100-0':
        entries.sort((a, b) => b.value.length.compareTo(a.value.length));
        break;
    }

    filteredGroups
      ..clear()
      ..addEntries(entries);

    setState(() {});
  }

  void _showSortDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _searchFocusNode.unfocus();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
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
                    color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                OptionMenu(
                  text: 'Name A-Z',
                  callbackAction: () {
                    setState(() {
                      _sortByOption = 'Sort By Name A-Z';
                      _filterGroups();
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
                      _filterGroups();
                    });
                    _searchFocusNode.unfocus();
                    Navigator.pop(context);
                  },
                ),
                OptionMenu(
                  text: 'Items 0-100',
                  callbackAction: () {
                    setState(() {
                      _sortByOption = 'Sort By Items 0-100';
                      _filterGroups();
                    });
                    _searchFocusNode.unfocus();
                    Navigator.pop(context);
                  },
                ),
                OptionMenu(
                  text: 'Items 100-0',
                  callbackAction: () {
                    setState(() {
                      _sortByOption = 'Sort By Items 100-0';
                      _filterGroups();
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
    ).whenComplete(() {
      _searchFocusNode.unfocus();
    });
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
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [Colors.blue.shade900, Colors.black87]
                    : [Colors.blue.shade100, Colors.blue.shade400],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Text(
                      'Folders',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  TapRegion(
                    onTapInside: (_) {}, // Prevent parent gestures from interfering
                    child: IOSSearchBar(
                      controller: searchController,
                      focusNode: _searchFocusNode,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _showSortDrawer(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _sortByOption,
                                  style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPickerPage(
                                      folderName: 'All Videos',
                                      videoPaths: allVideoPath,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  'assets/grid.svg',
                                  color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTapDown: (details) {
                                _tapPosition = details.globalPosition;
                                _animationController.forward();
                                themeProvider.toggleTheme(_tapPosition!);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  isDarkMode ? 'assets/sun.svg' : 'assets/moon.svg',
                                  color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_searchFocusNode.hasFocus) {
                          _searchFocusNode.unfocus();
                        }
                      },
                      child: _isLoading
                          ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.deepPurple : Colors.blue,
                          ),
                        ),
                      )
                          : filteredGroups.isEmpty
                          ? Center(
                        child: Text(
                          'No folders found',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      )
                          : RefreshIndicator(
                        onRefresh: _fetchAllVideoPaths,
                        child: FolderList(data: filteredGroups),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _explosionAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: ExplosionPainter(
                progress: _explosionAnimation.value,
                center: _tapPosition ?? Offset.zero,
                isDarkMode: isDarkMode,
              ),
            );
          },
        ),
      ],
    );
  }
}

class ExplosionPainter extends CustomPainter {
  final double progress;
  final Offset center;
  final bool isDarkMode;

  ExplosionPainter({required this.progress, required this.center, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.deepPurple.withOpacity(0.8 * (1 - progress)) : Colors.blue.withOpacity(0.8 * (1 - progress))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final radius = size.width * 2.5 * progress;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}