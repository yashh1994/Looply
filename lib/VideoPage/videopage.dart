import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  TextEditingController searchController = TextEditingController();

  String _sortByOption = 'Sort By'; // Tracks the selected sort option

  // Function to show the Apple-styled bottom drawer
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
  Widget build(BuildContext context) {
    final data = [
      {
        "name": "Folder 1",
        "number": 12,
      }
    ];

    return Scaffold(
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
              SearchBar(controller: searchController),
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
              FolderList(data: data)
            ],
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


class SearchBar extends StatelessWidget {
  const SearchBar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 10.0,
          ),
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          hintText: "Folder Name",
          prefixIcon: Icon(Icons.search),
          filled: false,
        ),
      ),
    );
  }
}



class FolderList extends StatelessWidget {
  const FolderList({super.key, required this.data});

  final List data;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // 3 columns
      crossAxisSpacing: 10, // Space between columns
      mainAxisSpacing: 10, // Space between rows
      childAspectRatio: 0.8, // Adjust the height/width ratio of grid items
    ), itemBuilder: (context, index) {
      final item = data[index];
      return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/folder_icon.svg',
            width: 24,
            height: 24,
          )
        ],
      ),
    );
    }));
  }
}
