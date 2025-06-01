import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:looply/Globals.dart';
import 'package:looply/VideoPage/FolderList.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  TextEditingController searchController = TextEditingController();
  Map<String, List<String>> groups = {};
  String _sortByOption = 'Sort By';
  bool _isLoading = false;
  List allVideoPath = [];
  Map<String, List<String>> filteredGroups = {};

  void _filterGroups() {
    final query = searchController.text.toLowerCase().trim();
    filteredGroups.clear();

    // Filter
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

    // Sort
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

    // Rebuild filteredGroups with sorted order
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sort by:',
                      style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
                    ),
                    OptionMenu(text: "Name A-Z", callbackAction: () {
                      setState(() {
                        _sortByOption = 'Sort By Name A-Z';
                      });
                      _filterGroups();
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                    }),
                    OptionMenu(text: "Name Z-A", callbackAction: () {
                      setState(() {
                        _sortByOption = 'Sort By Name Z-A';
                      });
                      _filterGroups();
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                    }),
                    OptionMenu(text: "Items 0-100", callbackAction: () {
                      setState(() {
                        _sortByOption = 'Sort By Items 0-100';
                      });
                      _filterGroups();
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                    }),
                    OptionMenu(text: "Items 100-0", callbackAction: () {
                      setState(() {
                        _sortByOption = 'Sort By Items 100-0';
                      });
                      _filterGroups();
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterGroups);
    _fetchAllVideoPaths();
  }

  Future<void> _fetchAllVideoPaths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<AssetPathEntity> videoFolders = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      List<AssetEntity> allVideos = [];

      for (final folder in videoFolders) {
        final videos = await folder.getAssetListPaged(page: 0, size: 1000);
        allVideos.addAll(videos);
      }

      for (var v in allVideos) {
        allVideoPath.add(await getVideoPath(v));
      }

      for (var pathh in allVideoPath) {
        final dirName = dirname(pathh);
        if (!groups.containsKey(dirName)) {
          groups[dirName] = [];
        }
        groups[dirName]!.add(pathh);
      }

      filteredGroups.addAll(groups);

      setState(() {
        _isLoading = false;
      });
    } catch (er) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> getVideoPath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path as String;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Folders',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                IOSSearchBar(controller: searchController),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _showSortDrawer(context),
                        child: Row(
                          children: [
                            const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                            Text(
                              _sortByOption,
                              style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.grid_on, color: Colors.blue),
                    ],
                  ),
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FolderList(data: filteredGroups),
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
  const IOSSearchBar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<IOSSearchBar> createState() => _IOSSearchBarState();
}

class _IOSSearchBarState extends State<IOSSearchBar> {
  FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        cursorColor: Colors.blueAccent,
        decoration: InputDecoration(
          hintText: "Search folders",
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}


