import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<String> videoPaths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetchVideos();
  }

  Future<void> _requestPermissionsAndFetchVideos() async {
    await _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      isLoading = true;
    });

    // Get common directories to search for videos
    List<Directory?> directories = [];
    try {
      final externalDir = await getExternalStorageDirectory();
      final downloadsDir = await getDownloadsDirectory();
      final docsDir = await getApplicationDocumentsDirectory();

      directories.add(externalDir);
      directories.add(downloadsDir);
      directories.add(docsDir);

      // Optionally, add root storage directory for Android
      if (Platform.isAndroid) {
        directories.add(Directory('/storage/emulated/0'));
      }
    } catch (e) {
      print('Error accessing directories: $e');
    }

    videoPaths.clear();

    // Supported video extensions
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv'];

    for (var dir in directories) {
      if (dir != null && await dir.exists()) {
        try {
          await for (var entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final path = entity.path;
              if (videoExtensions.any((ext) => path.toLowerCase().endsWith(ext))) {
                videoPaths.add(path);
              }
            }
          }
        } catch (e) {
          print('Error scanning directory ${dir.path}: $e');
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Videos'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : videoPaths.isEmpty
          ? Center(child: Text('No videos found'))
          : ListView.builder(
        itemCount: videoPaths.length,
        itemBuilder: (context, index) {
          final videoPath = videoPaths[index];
          return ListTile(
            title: Text(videoPath.split('/').last),
            subtitle: Text(videoPath),
            onTap: () {
              // Add logic to play video or navigate to player screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected: $videoPath')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestPermissionsAndFetchVideos,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Video List',
      ),
    );
  }
}