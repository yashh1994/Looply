import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:flutter/services.dart';
import 'package:looply/VideoPage/VideoPlayer.dart';
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
import 'package:looply/VideoPage/videopage.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final String? videoPath;

  const SplashScreen({
    super.key,
    this.videoPath,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        _controller.forward();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VideoPage()),
=======
=======
>>>>>>> Stashed changes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.videoPath == null
                ? VideoPage()
                : VideoPlayerScreen(videoPath: widget.videoPath!),
          ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Lottie.asset(
          isDarkMode ? 'assets/Lot/logo_dark.json' : 'assets/Lot/logo_blue.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
