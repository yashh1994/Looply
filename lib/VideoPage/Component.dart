
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looply/Globals.dart';
import 'package:looply/VideoPage/videopage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionMenu extends StatelessWidget {
  const OptionMenu({super.key, required this.text, required this.callbackAction});

  final String text;
  final VoidCallback callbackAction;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callbackAction,
        borderRadius: BorderRadius.circular(12),
        splashColor: (isDarkMode ? Colors.deepPurple : Colors.blue).withOpacity(0.3),
        highlightColor: (isDarkMode ? Colors.deepPurple : Colors.blue).withOpacity(0.1),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                color: isDarkMode ? Colors.deepPurple.shade300 : Colors.blue.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// Assuming ThemeProvider is defined in video_page.dart
// import 'package:looply/VideoPage/video_page.dart';
class IOSSearchBar extends StatefulWidget {
  const IOSSearchBar({super.key, required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<IOSSearchBar> createState() => _IOSSearchBarState();
}

class _IOSSearchBarState extends State<IOSSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? (isDarkMode ? Colors.deepPurple.withOpacity(0.6) : Colors.blue.withOpacity(0.6))
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.focusNode.hasFocus ? 0.3 : 0.1),
                    blurRadius: widget.focusNode.hasFocus ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                key: const ValueKey('searchTextField'),
                controller: widget.controller,
                focusNode: widget.focusNode,
                cursorColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search folders',
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Transform.scale(
                    scale: widget.focusNode.hasFocus ? 1.1 : 1.0,
                    child: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.focusNode.unfocus();
                      setState(() {}); // Refresh suffixIcon
                    },
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
