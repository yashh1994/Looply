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


  void _showSortDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent background for the sheet
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.only(top: 20), // Space for rounded corners at the top
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // Slightly transparent white background
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            border: Border.all(
              color: Colors.white24, // Apple-like light border
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drawer handle
              // Container(
              //   margin: const EdgeInsets.symmetric(vertical: 10),
              //   width: 40,
              //   height: 5,
              //   decoration: BoxDecoration(
              //     color: Colors.grey.shade300,
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Sort by: ',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.grey
                  ),
                ),
              ),
              // Sort options

             OptionMenu(text: "Date", callbackAction: () {
               setState(() {
                 _sortByOption = 'Sort By Date';
               });
               Navigator.pop(context);
             }),
              OptionMenu(text: "Name", callbackAction: () {
                setState(() {
                  _sortByOption = 'Sort By Name';
                });
                Navigator.pop(context);
              }),
              OptionMenu(text: "Time", callbackAction: () {
                setState(() {
                  _sortByOption = 'Sort By Time';
                });
                Navigator.pop(context);
              })
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchAllVideoPaths();
  }

  Future<void> _fetchAllVideoPaths() async {

    setState(() {
      _isLoading = true;
    });

    try{
      List<AssetPathEntity> videoFolders = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      List<AssetEntity> allVideos = [];

      for (final folder in videoFolders) {
        final videos = await folder.getAssetListPaged(page: 0, size: 1000);
        allVideos.addAll(videos);
      }


      for(var v in allVideos){
        allVideoPath.add(await getVideoPath(v));
      }

      pri(" ---------- GOT all VIDEOS PATH: ${allVideoPath}");



      for (var pathh in allVideoPath) {
        final dirName = dirname(pathh); // e.g. "/storage/emulated/0/DCIM/Camera"

        if (!groups.containsKey(dirName)) {
          groups[dirName] = []; // initialize the list if not present
        }

        groups[dirName]!.add(pathh);
      }

      setState(() {
        _isLoading = false;
      });

      pri(" ---------- Final Grouped Videos : ${groups}");
    }catch(er){
      pri("=========== ERROR FETCHING VIDEO PATH : ${er} ========== ");
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
    final data = [
      {
        "name": "Folder 1",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      },
      {
        "name": "Folder 1",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      },
      {
        "name": "Folder 1",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      },
      {
        "name": "Folder 1",
        "number": 12,
      },
      {
        "name": "Folder 2",
        "number": 12,
      },
      {
        "name": "Folder 3",
        "number": 12,
      },
      {
        "name": "Folder 4",
        "number": 12,
      }
    ];

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // iOS-style transparent
      statusBarIconBrightness: Brightness.dark, // Dark icons (for light backgrounds)
      statusBarBrightness: Brightness.light, // For iOS
    ));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Folders',
                    style: GoogleFonts.notoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),


                IOSSearchBar(controller: searchController),


                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showSortDrawer(context); // Open bottom drawer on tap
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.blue,
                            ),
                            Text(
                              _sortByOption, // Dynamically update text
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.grid_on,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

                if(_isLonding){

                }
                FolderList(data: groups)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OptionMenu extends StatelessWidget {
  const OptionMenu({
    super.key,
    required this.text,
    required this.callbackAction,
  });

  final String text;
  final VoidCallback callbackAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensure Material doesn't override transparency
      child: InkWell(
        onTap: callbackAction, // Trigger the callback when tapped
        borderRadius: BorderRadius.circular(8.0), // Match the container's border radius
        splashColor: Colors.grey.withOpacity(0.3), // Color of the ripple effect
        highlightColor: Colors.grey.withOpacity(0.1), // Color when pressed
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // Transparent background
            border: Border.all(
              color: Colors.grey.shade300, // Light gray border
              width: 0.5, // Thin border
            ),
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16.0,
              ),
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


// class FolderList extends StatelessWidget {
//   const FolderList({super.key, required this.data});
//
//   final Map<dynamic, dynamic> data;
//
//   @override
//   Widget build(BuildContext context) {
//     final double spacing = 16; // Equal padding and spacing
//     final double iconSize = 86;
//
//     return Expanded(
//       child: Padding(
//         padding: EdgeInsets.all(spacing),
//         child: GridView.builder(
//           itemCount: data.length,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             crossAxisSpacing: spacing,
//             mainAxisSpacing: spacing,
//             childAspectRatio: 0.75,
//           ),
//           itemBuilder: (context, index) {
//             final item = data[index];
//
//             return InkWell(
//               splashColor: Colors.transparent,
//               highlightColor: Colors.transparent,
//               onTap: () {},
//               child: Column(
//                 children: [
//                   Container(
//                     width: iconSize,
//                     height: iconSize,
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: SvgPicture.asset(
//                       'assets/icons/folder_icon.svg',
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     item['name'],
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                   SizedBox(height: 2),
//                   Text(
//                     "${item['number']} items",
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey,
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

