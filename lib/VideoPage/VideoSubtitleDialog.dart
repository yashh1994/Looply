import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

class CurrentSubtitleNotifier extends ValueNotifier<SubtitleTrack?> {
  CurrentSubtitleNotifier(SubtitleTrack? value) : super(value);

  void switchTrack(SubtitleTrack track) {
    value = track;
    notifyListeners();
  }
}

class SubtitleSelectionDialog extends StatefulWidget {
  const SubtitleSelectionDialog({
    super.key,
    required this.audioList,
    required this.onClick,
  });

  final List<SubtitleTrack> audioList;
  final void Function(SubtitleTrack) onClick;

  @override
  _SubtitleSelectionDialogState createState() => _SubtitleSelectionDialogState();
}

class _SubtitleSelectionDialogState extends State<SubtitleSelectionDialog> {
  late CurrentSubtitleNotifier currentSubtitleNotifier;

  @override
  void initState() {
    super.initState();
    currentSubtitleNotifier = CurrentSubtitleNotifier(
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
      child: Dialog(
        backgroundColor: Colors.transparent,
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
                  'Subtitle Tracks',
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
                          currentSubtitleNotifier.switchTrack(track);
                          widget.onClick(track);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              ValueListenableBuilder<SubtitleTrack?>(
                                valueListenable: currentSubtitleNotifier,
                                builder: (context, value, child) {
                                  return Radio<SubtitleTrack>(
                                    value: track,
                                    groupValue: value,
                                    onChanged: (SubtitleTrack? value) {
                                      if (value != null) {
                                        currentSubtitleNotifier.switchTrack(value);
                                        widget.onClick(value);
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Subtitle Track #${widget.audioList.indexOf(track) + 1} - ${track.language ?? 'Unknown'}",
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
                            'No subtitles found',
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
              ),
              if (widget.audioList.isNotEmpty)
                InkWell(
                  onTap: () {
                    SubtitleTrack disableTrack = SubtitleTrack(
                      "auto",
                      null,
                      null,
                      image: null,
                      albumart: null,
                      codec: null,
                      decoder: null,
                      w: null,
                      h: null,
                      channelscount: null,
                      channels: null,
                      samplerate: null,
                      fps: null,
                      bitrate: null,
                      rotate: null,
                      par: null,
                      audiochannels: null,
                    );
                    currentSubtitleNotifier.switchTrack(disableTrack);
                    widget.onClick(disableTrack);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ValueListenableBuilder<SubtitleTrack?>(
                          valueListenable: currentSubtitleNotifier,
                          builder: (context, value, child) {
                            return Radio<SubtitleTrack>(
                              value: SubtitleTrack(
                                "auto",
                                null,
                                null,
                                image: null,
                                albumart: null,
                                codec: null,
                                decoder: null,
                                w: null,
                                h: null,
                                channelscount: null,
                                channels: null,
                                samplerate: null,
                                fps: null,
                                bitrate: null,
                                rotate: null,
                                par: null,
                                audiochannels: null,
                              ),
                              groupValue: value,
                              onChanged: (SubtitleTrack? value) {
                                if (value != null) {
                                  currentSubtitleNotifier.switchTrack(value);
                                  widget.onClick(value);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Disable Subtitles",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
