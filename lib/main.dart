import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:looply/HomePage.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Globals.dart';

void main() {
  MediaKit.ensureInitialized(); // true or false
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoListScreen(),
        //home: Homepage(),
        home: VideoPlayerScreen(
      videoPath:
          "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video/VID-20250515-WA0006.mp4",
    ));
      home: AllVideosPage(),
    //     home: VideoPlayerScreen(
    //   videoPath:
    //       "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video/VID-20250515-WA0006.mp4",
    // )

    );
  }
}


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
    //fetchAllVideos();
  }


  Future<bool> requestPermissions() async {
    try{

    if (await Permission.videos.isGranted) {
      return true;
      pri("✅ Permission granted!");
    } else {
      findMp4AndMkvFiles();
    }
  }

  Future<List<String>> findMp4AndMkvFiles() async {
    // Request storage permission
    // var status = await Permission.storage.status;
    // if (status.isDenied) {
    //   status = await Permission.storage.request();
    //   if (status.isDenied) {
    //     // Handle permission denied case
    //     pri("---- Permission Denied: ----------");
    //     return [];
    //   }
    // }

    // Rest of your code to find mp4 and mkv files
    final externalStorageDirectory = await Directory("/storage/emulated/0");
    if (externalStorageDirectory == null) {
      pri("-------- Directory NUll --------");
      return []; // Handle case where external storage is not available
    }

    final List<String> mp4AndMkvFiles = [];

    await _searchDirectory(externalStorageDirectory, mp4AndMkvFiles);

    return mp4AndMkvFiles;
  }

  Future<void> _searchDirectory(
      Directory directory, List<String> mp4AndMkvFiles) async {
    final List<FileSystemEntity> entities = await directory.list().toList();
    pri("Files: ${entities}");
    for (final entity in entities) {
      if (entity is File) {
        pri("Checking file: ${entity}");
        final extension = entity.path.split('.').last.toLowerCase();
        if (extension == 'mp4' || extension == 'mkv') {
          mp4AndMkvFiles.add(entity.path);
        }
      } else if (entity is Directory) {
        pri("Go to ${entity}");
        await _searchDirectory(entity, mp4AndMkvFiles);
      }else{
        pri("Dont know what: ${entity}");
      var result = await Permission.videos.request();
      if (result.isGranted) {
        return true;
        pri("✅ Now granted!");
      } else {
        return false;
        pri("❌ Permission denied");
      }
    }
    }catch(er){
      pri("Somehting from Permissions: ${er} ------------ ");
      return false;
    }
  }


  Future<void> fetchAllVideos() async {
    try{
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
    );
  }
}

