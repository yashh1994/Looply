<<<<<<< Updated upstream
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';
//
// class VideoComparisonPage extends StatefulWidget {
//   @override
//   _VideoComparisonPageState createState() => _VideoComparisonPageState();
// }
//
// class _VideoComparisonPageState extends State<VideoComparisonPage> {
//   VideoPlayerController? _originalController;
//   VideoPlayerController? _enhancedController;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideos();
//   }
//
//   Future<String> enhanceVideo(String inputPath) async {
//     final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
//
//     final dir = await getTemporaryDirectory();
//     final outputPath = '${dir.path}/enhanced_video.mp4';
//
//     String command = "-i $inputPath -vf scale=1920:1080 $outputPath";
//
//     await _flutterFFmpeg.execute(command).then((rc) {
//       print("FFmpeg process exited with rc $rc");
//     });
//
//     return outputPath;
//   }
//
//   Future<void> _initializeVideos() async {
//     String videoPath = '/storage/emulated/0/Download/Telegram/naruto.mp4';
//     String enhancedVideoPath = await enhanceVideo(videoPath);
//
//     _originalController = VideoPlayerController.file(File(videoPath))
//       ..initialize().then((_) {
//         setState(() {});
//       });
//
//     _enhancedController = VideoPlayerController.file(File(enhancedVideoPath))
//       ..initialize().then((_) {
//         setState(() {});
//       });
//
//     // Synchronize the start time of both videos
//     _originalController?.addListener(_syncVideos);
//     _enhancedController?.addListener(_syncVideos);
//   }
//
//   void _syncVideos() {
//     if (_originalController != null && _enhancedController != null) {
//       if (_originalController!.value.isPlaying) {
//         final originalPosition = _originalController!.value.position;
//         _enhancedController!.seekTo(originalPosition);
//       } else if (_enhancedController!.value.isPlaying) {
//         final enhancedPosition = _enhancedController!.value.position;
//         _originalController!.seekTo(enhancedPosition);
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _originalController?.removeListener(_syncVideos);
//     _enhancedController?.removeListener(_syncVideos);
//     _originalController?.dispose();
//     _enhancedController?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Comparison'),
//       ),
//       body: Column(
//         children: [
//           if (_originalController?.value.isInitialized ?? false)
//             _buildVideoPlayer(_originalController!, 'Original Video'),
//           if (_enhancedController?.value.isInitialized ?? false)
//             _buildVideoPlayer(_enhancedController!, 'Enhanced Video'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoPlayer(VideoPlayerController controller, String title) {
//     return Column(
//       children: [
//         Text(title),
//         AspectRatio(
//           aspectRatio: controller.value.aspectRatio,
//           child: VideoPlayer(controller),
//         ),
//         VideoProgressIndicator(controller, allowScrubbing: true),
//         Row(
//           children: [
//             IconButton(
//               icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
//               onPressed: () {
//                 setState(() {
//                   if (_originalController!.value.isPlaying) {
//                     _originalController?.pause();
//                     _enhancedController?.pause();
//                   } else {
//                     _originalController?.play();
//                     _enhancedController?.play();
//                   }
//                 });
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
=======
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'Globals.dart';
import 'package:permission_handler/permission_handler.dart';


class AllVideosPage extends StatefulWidget {
  @override
  _AllVideosPageState createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
  List<AssetEntity> videoAssets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    pri("Starting Now");
    fetchAllVideos();
  }


  Future<bool> requestPermissions() async {
    try{
      if (await Permission.videos.isGranted) {
        pri("✅ Permission granted!");
        return true;
      } else {
        var result = await Permission.videos.request();
        if (result.isGranted) {
          pri("✅ Now granted!");
          return true;
        } else {
          pri("❌ Permission denied");
          return false;
        }
      }
    }catch(er){
      pri("Somehting from Permissions: ${er} ------------ ");
      return false;
    }
  }


  Future<void> fetchAllVideos() async {
    try{
      pri("Asking Permission: ");
      final permission = await requestPermissions();

      if (!permission) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<AssetPathEntity> videoFolders = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      List<AssetEntity> allVideos = [];

      for (final folder in videoFolders) {
        final videos = await folder.getAssetListPaged(page: 0, size: 1000);
        allVideos.addAll(videos);
      }

      var temp = [];
      for(var v in allVideos){
        temp.add(await getVideoPath(v));
      }

      pri(" ------------------------ Got All Videos: ${temp}");
      setState(() {
        videoAssets = allVideos;
        isLoading = false;
      });
    }catch(er){
      pri("_________ Erro whileing fetching videos: ${er} __________");
    }
  }

  Future<String?> getVideoPath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Videos")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: videoAssets.length,
        itemBuilder: (context, index) {
          final video = videoAssets[index];
          return FutureBuilder<String?>(
            future: getVideoPath(video),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListTile(title: Text("Loading..."));
              }
              final path = snapshot.data;
              if (path == null) return SizedBox.shrink();
              return ListTile(
                leading: Icon(Icons.videocam),
                title: Text(path.split('/').last),
                subtitle: Text(path),
              );
            },
          );
        },
      ),
      // body: Container(color: Colors.amber,),
    );
  }
}

>>>>>>> Stashed changes
