import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PlayPauseNotifier extends ValueNotifier<bool> {
  PlayPauseNotifier(bool value) : super(value);

  void toggle(bool val) {
    value = val;
    notifyListeners();
  }
}

class PlayPauseButton extends StatefulWidget {
  final String animationPath;
  final Duration duration;
  final double width;
  final double height;
  final PlayPauseNotifier notifier;
   bool isPlay;

  PlayPauseButton({
    required this.animationPath,
    required this.duration,
    required this.notifier,
    this.width = 100.0, // Default width
    this.height = 100.0,
    required this.isPlay// Default height
  });

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    widget.notifier.addListener(() {
      if (widget.notifier.value) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 0.3);
      }
    });
  }

  @override
  void dispose() {
    widget.notifier.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Lottie.asset(
        widget.animationPath,
        controller: _controller,
        onLoaded: (composition) {
          _controller..duration = Duration(milliseconds: 500);
        },
      ),
    );
  }
}
