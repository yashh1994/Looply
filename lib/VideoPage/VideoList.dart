import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';

class VideoPickerPage extends StatefulWidget {
  final String folderName;
  final List<String> videoPaths;

  const VideoPickerPage({
    Key? key,
    required this.folderName,
    required this.videoPaths,
  }) : super(key: key);

  @override
  _VideoPickerPageState createState() => _VideoPickerPageState();
}

class _VideoPickerPageState extends State<VideoPickerPage> {
  final FlutterVideoInfo _flutterVideoInfo = FlutterVideoInfo();
  final Map<String, VideoData> _videoMeta = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    for (final path in widget.videoPaths) {
      final info = await _flutterVideoInfo.getVideoInfo(path);
      if (info != null) {
        _videoMeta[path] = info;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDuration(int? millis) {
    if (millis == null) return '--:--';
    final duration = Duration(milliseconds: millis);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '--';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.videoPaths.length,
        itemBuilder: (context, index) {
          final path = widget.videoPaths[index];
          final info = _videoMeta[path];

          return GestureDetector(
            onTap: () {
              // Handle video tap
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(info?.duration as int),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatBytes(info?.filesize),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
