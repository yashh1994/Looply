// import 'dart:io';
// import 'package:looply/HomePage.dart';
// import 'package:looply/VideoPage/VideoPlayer.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:looply/VideoPage/VideoPlayer.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'Globals.dart';
//
// void main() {
//   MediaKit.ensureInitialized(); // true or false
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         //home: Homepage(),
//         home: VideoPlayerScreen(
//       videoPath:
//           "/storage/emulated/0/DCIM/Camera/VID_20241122_110548.mp4",
//     ));
//   }
// }
//
// class VideoListScreen extends StatefulWidget {
//   @override
//   _VideoListScreenState createState() => _VideoListScreenState();
// }
//
// class _VideoListScreenState extends State<VideoListScreen> {
//   List<String> videoPaths = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     findMp4AndMkvFiles();
//   }
//
//   Future<void> loadVideoPaths() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedPaths = prefs.getStringList('videoPaths');
//
//     if (cachedPaths != null && cachedPaths.isNotEmpty) {
//       setState(() {
//         videoPaths = cachedPaths;
//         isLoading = false;
//       });
//     } else {
//       findMp4AndMkvFiles();
//     }
//   }
//
//   Future<List<String>> findMp4AndMkvFiles() async {
//     // Request storage permission
//     var status = await Permission.storage.status;
//     if (status.isDenied) {
//       status = await Permission.storage.request();
//       if (status.isDenied) {
//         // Handle permission denied case
//         pri("---- Permission Denied: ----------");
//         return [];
//       }
//     }
//
//     // Rest of your code to find mp4 and mkv files
//     final externalStorageDirectory = await getExternalStorageDirectory();
//     if (externalStorageDirectory == null) {
//       pri("-------- Directory NUll --------");
//       return []; // Handle case where external storage is not available
//     }
//
//     final List<String> mp4AndMkvFiles = [];
//
//     await _searchDirectory(externalStorageDirectory, mp4AndMkvFiles);
//
//     return mp4AndMkvFiles;
//   }
//
//   Future<void> _searchDirectory(
//       Directory directory, List<String> mp4AndMkvFiles) async {
//     final List<FileSystemEntity> entities = await directory.list().toList();
//
//     for (final entity in entities) {
//       pri('go thoug ${entity.path} ----------');
//       if (entity is File) {
//         final extension = entity.path.split('.').last.toLowerCase();
//         if (extension == 'mp4' || extension == 'mkv') {
//           mp4AndMkvFiles.add(entity.path);
//         }
//       } else if (entity is Directory) {
//         await _searchDirectory(entity, mp4AndMkvFiles);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video List'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: videoPaths.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(videoPaths[index]),
//                 );
//               },
//             ),
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(home: VideoPlayerScreen()));
}

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  final String videoPath = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video/VID-20250515-WA0006.mp4';

  @override
  void initState() {
    super.initState();
    // Request permission and initialize video after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndPlay();
    });
  }

  Future<void> _requestPermissionAndPlay() async {

    PermissionStatus permissionResult = await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
    if (permissionResult == PermissionStatus.authorized){
      // Check if file exists
      final file = File(videoPath);
      final exists = await file.exists();
      print('Video file exists: $exists');
      if (!exists) {
        _showFileNotFoundDialog();
        return;
      }

      // Initialize video player
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller!.play();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permission denied'),
        content: Text('Storage permission is required to play the video.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  void _showFileNotFoundDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('File not found'),
        content: Text('Video file not found at:\n$videoPath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Local Video Player')),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        )
            : Text('Loading video or waiting for permission...'),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller!.value.isPlaying
                ? _controller!.pause()
                : _controller!.play();
          });
        },
        child: Icon(
          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}

