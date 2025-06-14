import 'dart:io';

import 'package:looply/HomePage.dart';
import 'package:looply/SplashScreen.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:looply/VideoPage/videopage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Globals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child:  MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _videoPath;

  @override
  void initState() {
    super.initState();



    // Handle initial intent (when app is launched via "Open with")
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleVideoIntent(value.first.path);
      }
    });

    // Listen for intents while the app is running
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        pri("This is what i got: ${value.first.path}");
        // _handleVideoIntent(value.first.path);
      }
    }, onError: (err) {
      pri("Error receiving intent: $err");
    });
  }

  Future<void> _handleVideoIntent(String uri) async {
    try {
      final filepath = await uriToFilePath(uri);
      setState(() {
        _videoPath = filepath;
      });
    } catch (e) {
      pri("Error handling video URI: $e");
      Fluttertoast.showToast(msg: "Failed to load video: $e");
    }
  }

  Future<String> uriToFilePath(String uri) async {
    if (uri.startsWith('file://')) {
      return uri.replaceFirst('file://', '');
    } else if (uri.startsWith('content://')) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      final bytes = await File(uri).readAsBytes();
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } else if (File(uri).existsSync()) {
      // Direct file path (already valid)
      return uri;
    } else {
      throw Exception('Unsupported URI scheme: $uri');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData(
            primaryColor: Colors.blue.shade700,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
          ),
          darkTheme: ThemeData(
            primaryColor: Colors.deepPurple.shade300,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurple,
              secondary: Colors.deepPurpleAccent,
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: SplashScreen(videoPath: _videoPath));
                }
    );
  }
}