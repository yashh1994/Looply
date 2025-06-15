import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looply/VideoPage/FolderList.dart';
import 'package:looply/VideoPage/VideoList.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:looply/Globals.dart';


class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
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

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with RouteAware {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  Map<String, List<String>> groups = {};
  Map<String, List<String>> filteredGroups = {};
  String _sortByOption = 'Sort By';
  bool _isLoading = false;
  List<String> allVideoPath = [];
  final FlutterVideoInfo _flutterVideoInfo = FlutterVideoInfo();
  final Map<String, VideoData> _videoMeta = {};
  String lastVideoPath = "";

  bool _isPermissionGranndted = false;



  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterGroups);
    _checkForPermission();
  }

  Future<void> _askPermission() async {
    try{
      var result = await Permission.videos.request();
      if (result.isGranted) {
        pri("✅ Now granted!");
        setState(() {
          _isPermissionGranndted = true;
        });
        _fetchAllVideoPaths();
      }
    }catch(er){
      pri("------ Problem Asking Permission: $er -------------");
    }
  }

  Future<void> _checkForPermission() async {
    setState(() {
      _isLoading = true;
      _isPermissionGranndted = false;
    });
  try{
    if (await Permission.videos.status.isGranted) {
      pri("✅ Permission granted!");
      setState(() {
        _isPermissionGranndted = true;
      });
      _fetchAllVideoPaths();
    } else {

      setState(() {
        _isLoading = false;
        _isPermissionGranndted = false;
      });

      // var result = await Permission.videos.request();
      // if (result.isGranted) {
      //   pri("✅ Now granted!");
      //   setState(() {
      //     _isPermissionGranndted = true;
      //   });
      //   _fetchAllVideoPaths();
      // } else {
      //   pri("❌ Permission denied");
      //   setState(() {
      //     _isLoading = false;
      //     _isPermissionGranndted = false;
      //   });
      // }
    }
  }catch(er){
    setState(() {
      _isLoading = false;
      _isPermissionGranndted = true;
    });
    pri("Something from Permissions: ${er} ------------ ");
  }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchFocusNode.unfocus();
  }

  @override
  void didPopNext() {
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

Future<void> _fetchVideoPathFromPhotomanager()async{
    setState(() {
      _isLoading = true;
    });

    try{
      final videoFolders = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      List<AssetEntity> allVideos = [];
      for (final folder in videoFolders) {
        final videos = await folder.getAssetListPaged(page: 0, size: 1000);
        allVideos.addAll(videos);
      }
      allVideoPath = (await Future.wait(allVideos.map((v) => getVideoPath(v)))).where((path) => path.isNotEmpty).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_video_paths', allVideoPath);

      for (var path in allVideoPath) {
        final info = await _flutterVideoInfo.getVideoInfo(path);
        if (info != null) {
          _videoMeta[path] = info;
        }
        final dirName = p.dirname(path);
        groups.putIfAbsent(dirName, () => []).add(path);
      }

      filteredGroups.clear();
      filteredGroups.addAll(groups);
      _filterGroups();
      pri("All Grouped Videos: $groups");
      pri("Video Metadata: $_videoMeta");
      setState(() {
        _isLoading = false;
      });

    }catch(er){

      setState(() {
        _isLoading = false;
      });
    }
}


  Future<void> _fetchAllVideoPaths() async {

    setState(() {
      _isLoading = true;
    });

    try{
      final prefs = await SharedPreferences.getInstance();
      List<String>? _allV = prefs.getStringList('cached_video_paths');

      if(_allV != null && _allV.isNotEmpty){
        allVideoPath = _allV;
      }else{
        final videoFolders = await PhotoManager.getAssetPathList(
          type: RequestType.video,
          onlyAll: true,
        );

        List<AssetEntity> allVideos = [];
        for (final folder in videoFolders) {
          final videos = await folder.getAssetListPaged(page: 0, size: 1000);
          allVideos.addAll(videos);
        }
        allVideoPath = (await Future.wait(allVideos.map((v) => getVideoPath(v)))).where((path) => path.isNotEmpty).toList();
        await prefs.setStringList('cached_video_paths', allVideoPath);
      }

      for (var path in allVideoPath) {
        final info = await _flutterVideoInfo.getVideoInfo(path);
        if (info != null) {
          _videoMeta[path] = info;
        }
        final dirName = p.dirname(path);
        groups.putIfAbsent(dirName, () => []).add(path);
      }

      filteredGroups.clear();
      filteredGroups.addAll(groups);
      _filterGroups();
      pri("All Grouped Videos: $groups");
      pri("Video Metadata: $_videoMeta");
      setState(() {
        _isLoading = false;
      });
    }catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching videos: $e')),
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
        final folderName = p.basename(key).toLowerCase();
        if (folderName.contains(query)) {
          filteredGroups[key] = value;
        }
      });
    }

    final entries = filteredGroups.entries.toList();

    switch (_sortByOption) {
      case 'Sort By Name A-Z':
        entries.sort((a, b) => p.basename(a.key).toLowerCase().compareTo(p.basename(b.key).toLowerCase()));
        break;
      case 'Sort By Name Z-A':
        entries.sort((a, b) => p.basename(b.key).toLowerCase().compareTo(p.basename(a.key).toLowerCase()));
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

  Future<void> _loadLastVideo() async {
    final prefs = await SharedPreferences.getInstance();
    final ls = prefs.getString('last_video');
    if (ls != null) {
      lastVideoPath = ls;
    }else{
      lastVideoPath = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);

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
            child: Stack(
              children:[ Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Text(
                      'Folders',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: isDarkMode ? Colors.white : Colors.blue.shade900,
                      ),
                    ),
                  ),
                  IOSSearchBar(
                    controller: searchController,
                    focusNode: _searchFocusNode,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPickerPage(
                                      videoMeta: _videoMeta,
                                      folderName: 'All Videos',
                                      videoPaths: allVideoPath,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                child: Icon(Icons.grid_on,
                                    size: 24,color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                themeProvider.toggleTheme();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                child: Icon(isDarkMode ? Icons.sunny : Icons.nightlight,
                                size: 24,color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue),
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
                    child: _isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.deepPurple : Colors.blueAccent,
                        ),
                      ),
                    ): !_isPermissionGranndted ? Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off_rounded, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Storage permission required. Please enable it in the app settings.',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(Icons.lock_open),
                              label: Text('Grant Permission'),
                              onPressed: _askPermission,
                            ),
                          ],
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
                        : FolderList(data: filteredGroups,metadata: _videoMeta,onRefresh: () async {
                          await _fetchVideoPathFromPhotomanager();
                    },),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    await _loadLastVideo();
                    if(lastVideoPath.isNotEmpty){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(videoPath: lastVideoPath,)));
                    }else{
                      Fluttertoast.showToast(msg: "No Last Video");
                    }
                  },
                  backgroundColor: theme.primaryColor,
                  foregroundColor: isDarkMode ? Colors.white : Colors.white,
                  elevation: 6.0,
                  child:  Icon(Icons.play_arrow_rounded),
                  tooltip: 'Resume Last Video',
                )
              ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}


class FolderList extends StatelessWidget {
  const FolderList({super.key, required this.data,required this.metadata, required this.onRefresh});

  final Map<String, List<String>> data;

  final Map<String, VideoData> metadata;

  final Future<void> Function() onRefresh;


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    const double spacing = 16;
    const double iconSize = 80;

    final entries = data.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(spacing),
      child: RefreshIndicator(
        onRefresh: ()  {
          return onRefresh();
        },
        child: AnimationLimiter(
          child: GridView.builder(
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final folderPath = entry.key;
              final videoPaths = entry.value;
              final folderName = p.basename(folderPath);

              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 500),
                columnCount: 3,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPickerPage(
                              folderName: folderName,
                              videoPaths: videoPaths,
                              videoMeta: metadata,
                            ),
                          ),
                        );
                        FocusScope.of(context).unfocus();
                      },
                      child: Column(
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/folder_icon.svg',
                              fit: BoxFit.contain,
                              color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              folderName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.blue.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${videoPaths.length} item${videoPaths.length == 1 ? '' : 's'}",
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);



  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            hintText: 'Search folders',
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
      ),
    );
  }
}


