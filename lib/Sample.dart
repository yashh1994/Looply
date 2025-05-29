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

