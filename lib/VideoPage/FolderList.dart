import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:looply/Globals.dart';
import 'package:looply/VideoPage/VideoList.dart';
import 'package:looply/VideoPage/videopage.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

// Placeholder for VideoPickerPage (use from artifact_id: 9a96cf56-e903-47cd-8339-d74ead575163)
// import 'package:looply/VideoPage/VideoPickerPage.dart';
// Assuming ThemeProvider is defined in video_page.dart
// import 'package:looply/VideoPage/video_page.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key, required this.data,required this.metadata});

  final Map<String, VideoData> metadata;
  final Map<String, List<String>> data;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    const double spacing = 16;
    const double iconSize = 80;

    final entries = data.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(spacing),
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
                            videoMeta: this.metadata,
                            folderName: folderName,
                            videoPaths: videoPaths,
                          ),
                        ),
                      );
                      FocusScope.of(context).unfocus();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
              ),
            );
          },
        ),
      ),
    );
  }
}