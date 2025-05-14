import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:list_all_videos/list_all_videos.dart';
import 'package:list_all_videos/model/video_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:list_all_videos/thumbnail/ThumbnailTile.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
import 'VideoPlayer.dart';

class VideoPage extends StatelessWidget {
  VideoPage({Key? key}) : super(key: key);

  Future<List<VideoDetails>> fetchVideo() async {
    Fluttertoast.showToast(msg: 'Fetching');
    List<VideoDetails> list = await ListAllVideos().getAllVideosPath();
    Fluttertoast.showToast(msg: 'Fetching Complete');
    if (list.isEmpty) {
      Fluttertoast.showToast(msg: 'No videos found');
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Page'),
      ),
      body: FutureBuilder<List<VideoDetails>>(
        future: fetchVideo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Data Found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return VideoNode(video: snapshot.data![index]);
              },
            );
          }
        },
      ),
    );
  }
}

class VideoNode extends StatelessWidget {
  final VideoDetails video;

  const VideoNode({Key? key, required this.video}) : super(key: key);

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
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () async{
        var d = await getVideoDetails(video.videoPath);
        _showVideoDetailsDialog(context, d);
      },
      onTap: () {
        // Handle video playback or other actions here
        Fluttertoast.showToast(msg: 'Video tapped: ${video.videoName}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoPath: video.videoPath),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(6),
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 100,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ThumbnailTile(
                    thumbnailController: video.thumbnailController,
                  )
                )),
            SizedBox(
                width: 12), // Add some spacing between the image and the text
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video.videoName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      video.videoPath,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 65, 61, 61),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        LabelText(labelText: '123Mb'),
                        SizedBox(width: 8),
                        LabelText(labelText: '720p'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabelText extends StatelessWidget {
  final String labelText;

  const LabelText({Key? key, required this.labelText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Color.fromARGB(255, 195, 195, 219),
      ),
      child: Text(
        labelText,
        style: TextStyle(
            color: Color.fromARGB(255, 32, 32, 143),
            fontWeight: FontWeight.bold,
            fontSize: 10),
      ),
    );
  }
}
