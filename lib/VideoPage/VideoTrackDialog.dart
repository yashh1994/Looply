import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

class CurrentAudioTrackNotifier extends ValueNotifier<AudioTrack?> {
  CurrentAudioTrackNotifier(AudioTrack? value) : super(value);

  void switchTrack(AudioTrack track) {
    value = track;
    notifyListeners();
  }
}

class AudioTrackSelectionDialog extends StatefulWidget {
  const AudioTrackSelectionDialog({
    super.key,
    required this.audioList,
    required this.onClick,
  });

  final List<AudioTrack> audioList;
  final void Function(AudioTrack) onClick;

  @override
  _AudioTrackSelectionDialogState createState() => _AudioTrackSelectionDialogState();
}

class _AudioTrackSelectionDialogState extends State<AudioTrackSelectionDialog> {
  late CurrentAudioTrackNotifier currentAudioTrackNotifier;

  @override
  void initState() {
    super.initState();
    currentAudioTrackNotifier = CurrentAudioTrackNotifier(
      widget.audioList.isNotEmpty ? widget.audioList[0] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isLandscape = width > height;

    return Container(
      height: isLandscape ? height * 0.8 : height * 0.65,
      width: isLandscape ? width * 0.7 : width * 0.9,
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        content: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: Text(
                    'Audio Tracks',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.audioList.isNotEmpty
                          ? widget.audioList.map((track) {
                        return InkWell(
                          onTap: () {
                            currentAudioTrackNotifier.switchTrack(track);
                            widget.onClick(track);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                ValueListenableBuilder<AudioTrack?>(
                                  valueListenable: currentAudioTrackNotifier,
                                  builder: (context, value, child) {
                                    return Radio<AudioTrack>(
                                      value: track,
                                      groupValue: value,
                                      onChanged: (AudioTrack? value) {
                                        if (value != null) {
                                          currentAudioTrackNotifier.switchTrack(value);
                                          widget.onClick(value);
                                        }
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${track.title} - ${track.language}",
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                          : [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No audio tracks found',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
