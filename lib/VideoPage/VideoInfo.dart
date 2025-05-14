import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';




class VideoInfoIcon extends StatelessWidget {
  final String videoPath;
  final BuildContext context;
  const VideoInfoIcon({super.key, required this.videoPath, required this.context});



  Future<Map<String, dynamic>> getVideoDetails(String videoPath) async {
    final videoInfo = FlutterVideoInfo();
    var info = await videoInfo.getVideoInfo(videoPath);

    return {
      'Duration': info?.duration != null ? '${info?.duration} ms' : 'N/A',
      'Width': info?.width != null ? '${info?.width} px' : 'N/A',
      'Height': info?.height != null ? '${info?.height} px' : 'N/A',
      'Resolution': info != null ? '${info.width} x ${info.height} px' : 'N/A',
      'Size':'${((info?.filesize as int) / (1024 * 1024)).toStringAsFixed(2)} MB',
      'Path': info?.path ?? 'N/A',
      'Title': info?.title ?? 'N/A',
      'MimeType': info?.mimetype ?? 'N/A',
    };
  }

  void _showVideoDetailsDialog(BuildContext context, Map<String, dynamic> videoDetails) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: Text(
            'Video Details',
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: videoDetails.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${entry.key}:',
                          style: GoogleFonts.notoSans(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${entry.value}',
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: GoogleFonts.notoSans(
                  color: Colors.amber,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext con) {
    return InkWell(
      onTap: () async {
        var de = await getVideoDetails(videoPath);
        _showVideoDetailsDialog(context,de);
      },
      child: Container(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.all(6),
          color: Colors.transparent,
          child: Icon(Icons.info,size: 25,color: Colors.white,)),
    );
  }
}
