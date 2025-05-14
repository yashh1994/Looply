import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoComparisonPage extends StatefulWidget {
  @override
  _VideoComparisonPageState createState() => _VideoComparisonPageState();
}

class _VideoComparisonPageState extends State<VideoComparisonPage> {
  VideoPlayerController? _originalController;
  VideoPlayerController? _enhancedController;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<String> enhanceVideo(String inputPath) async {
    final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/enhanced_video.mp4';

    String command = "-i $inputPath -vf scale=1920:1080 $outputPath";

    await _flutterFFmpeg.execute(command).then((rc) {
      print("FFmpeg process exited with rc $rc");
    });

    return outputPath;
  }

  Future<void> _initializeVideos() async {
    String videoPath = '/storage/emulated/0/Download/Telegram/naruto.mp4';
    String enhancedVideoPath = await enhanceVideo(videoPath);

    _originalController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
      });

    _enhancedController = VideoPlayerController.file(File(enhancedVideoPath))
      ..initialize().then((_) {
        setState(() {});
      });

    // Synchronize the start time of both videos
    _originalController?.addListener(_syncVideos);
    _enhancedController?.addListener(_syncVideos);
  }

  void _syncVideos() {
    if (_originalController != null && _enhancedController != null) {
      if (_originalController!.value.isPlaying) {
        final originalPosition = _originalController!.value.position;
        _enhancedController!.seekTo(originalPosition);
      } else if (_enhancedController!.value.isPlaying) {
        final enhancedPosition = _enhancedController!.value.position;
        _originalController!.seekTo(enhancedPosition);
      }
    }
  }

  @override
  void dispose() {
    _originalController?.removeListener(_syncVideos);
    _enhancedController?.removeListener(_syncVideos);
    _originalController?.dispose();
    _enhancedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Comparison'),
      ),
      body: Column(
        children: [
          if (_originalController?.value.isInitialized ?? false)
            _buildVideoPlayer(_originalController!, 'Original Video'),
          if (_enhancedController?.value.isInitialized ?? false)
            _buildVideoPlayer(_enhancedController!, 'Enhanced Video'),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller, String title) {
    return Column(
      children: [
        Text(title),
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        VideoProgressIndicator(controller, allowScrubbing: true),
        Row(
          children: [
            IconButton(
              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  if (_originalController!.value.isPlaying) {
                    _originalController?.pause();
                    _enhancedController?.pause();
                  } else {
                    _originalController?.play();
                    _enhancedController?.play();
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
