import 'package:looply_draft/HomePage.dart';
import 'package:looply_draft/VideoPage/VideoPlayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:looply_draft/VideoPage/VideoPlayer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Globals.dart';
import 'Sample.dart';

void main() {
  MediaKit.ensureInitialized(); // true or false
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       // home: Container(color: Colors.amber,)
       // home: AllVideosPage(),
        home: VideoPlayerScreen(
      videoPath:
          "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video/VID-20250515-WA0006.mp4",
    )

    );
  }
}

