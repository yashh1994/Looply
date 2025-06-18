import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:looply/SplashScreen.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
import 'package:looply/VideoPage/videopage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'Globals.dart';
import 'package:provider/provider.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.looply/files');
  String? sharedVideoPath;

  @override
  void initState() {
    super.initState();

    // 🔁 Handle media while app is running
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) async {
      if (value.isNotEmpty) {
        final path = await uriToFilePath(value.first.path);
        Fluttertoast.showToast(msg: "Received media: $path");
        pri("Received Media (live): $path");
        if (!mounted) return;
        setState(() {
          sharedVideoPath = path;
        });
      }
    }, onError: (err) {
      pri("Error receiving intent: $err");
    });

    // 🚀 Handle media when app is launched via "open with"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialIntent();
    });
  }

  Future<void> _handleInitialIntent() async {
    try {
      final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initialMedia.isNotEmpty) {
        final path = await uriToFilePath(initialMedia.first.path);
        pri("Received Media (initial): $path");
        if (!mounted) return;
        setState(() {
          sharedVideoPath = path;
        });
      }
    } catch (e) {
      pri("Failed to handle initial intent: $e");
      Fluttertoast.showToast(msg: "Failed to open video: $e");
    }
  }

  /// 🔧 Resolves content:// or file:// to usable path
  Future<String> uriToFilePath(String uri) async {
    if (uri.startsWith('file://')) {
      return uri.replaceFirst('file://', '');
    } else if (uri.startsWith('content://')) {
      try {
        final path = await platform.invokeMethod<String>('getFilePathFromUri', {'uri': uri});
        if (path != null) return path;
        throw Exception('Failed to resolve URI');
      } catch (e) {
        throw Exception('Platform error: $e');
      }
    } else if (File(uri).existsSync()) {
      return uri;
    } else {
      throw Exception('Unsupported URI scheme: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
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
          home: sharedVideoPath != null
              ? VideoPlayerScreen(videoPath: sharedVideoPath!)
              : SplashScreen(videoPath: null),
        );
      },
    );
  }
}
