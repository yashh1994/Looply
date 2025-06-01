import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looply/VideoPage/VideoList.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key, required this.data});

  final Map<String, List<String>> data;

  @override
  Widget build(BuildContext context) {
    final double spacing = 16;
    final double iconSize = 86;

    final entries = data.entries.toList();

    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: AnimationLimiter(
          child: GridView.builder(
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                duration: Duration(milliseconds: 500),
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
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/folder_icon.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              folderName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${videoPaths.length} items",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          )
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
