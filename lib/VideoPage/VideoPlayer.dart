import 'dart:math';
import 'dart:ui';
import 'package:looply/Theme/GlobalTheme.dart';
import 'package:looply/VideoPage/VideoInfo.dart';
import 'package:looply/VideoPage/VideoSubtitleDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import '../Globals.dart';
import 'PlayPauseState.dart';
import 'VideoTrackDialog.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  VideoPlayerScreen({required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoController mediakit_controller;
  late Player player;

  bool _showOverlay = false;

  bool _isPlaying = false;

  Timer? _overlayTimer;
  Timer? _positionUpdateTimer;

  String _swipwSkipeMessage = '';
  double _swipeDistance = 0;

  double _swipeVolumeDistance = 0;

  double _swipeBrightDistance = 0;

  late String fileName;
  final PlayPauseNotifier playPauseNotifier = PlayPauseNotifier(true);
  CurrentAudioTrackNotifier? currentAudioTrackNotifier;
  CurrentSubtitleNotifier? currentSubtitleNotifier;
  bool _volumeVisible = false;
  bool _brightNessVisible = false;

  bool _skipMessageVisible = false;

  List<AudioTrack> _audioList = [];
  List<SubtitleTrack> _subtitles = [];

  bool _isAudioSelectionVisisble = false;
  bool _isSubtitleSelectionVisible = false;

  bool _isReadyToPlay = true;
  late Stream<String> subtitleStream; // Stream for subtitle text

  String screenOrien = "free";

  bool _isOrientationLocked = false;
  Orientation _currentOrientation = Orientation.portrait;

  late ScreenshotController screenshotController;

  bool screenLockMode = false;

  bool _isEyeOpen = false;

  double _intensityEye = 0.0;

  double _intensityVideoSpeed = 1.0;

  int? videoHeight;

  int? videoWidth;
  int screenFitModeNotifier = 1; // Create a [VideoController] to handle video output from [Player].
  //  late VideoController controller;
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black.withOpacity(0.9),
        statusBarIconBrightness: Brightness.light,
      ),
    );


    try{
      screenshotController = ScreenshotController();
      pri("-------- VIDEO FOR PLAYING: ${widget.videoPath} --------");
      fileName = p.basename(widget.videoPath);
      subtitleStream = Stream.periodic(Duration(seconds: 2), (count) {
        return "Subtitle ${count + 1}"; // Dynamic subtitle change
      });
      setUpPlayer();
      pri("----- Calling for dimentions -----");
      getVideoDimensions(widget.videoPath);
    }catch(er){
      pri("------- Error Ininitle: ${er} -----------");
      Fluttertoast.showToast(msg: 'something wrong');
    }
  }

  @override
  void dispose() {
    player.dispose();
    _overlayTimer?.cancel();
    _positionUpdateTimer?.cancel();
    super.dispose();
  }



  Future<void> getVideoDimensions(String filePath) async {
    try {
      final videoInfo = FlutterVideoInfo();
      pri("Getting info for: $filePath");

      final info = await videoInfo.getVideoInfo(filePath);
      videoHeight = info?.height;
      videoWidth = info?.width;
      if (info == null) {
        pri("getVideoInfo returned null");
      } else {
        pri("Raw info object: $info");

        // Try printing each field safely
        pri("height: ${info.height}");
        pri("width: ${info.width}");
        pri("duration: ${info.duration}");
        pri("author: ${info.author ?? 'null'}");
        pri("title: ${info.title ?? 'null'}");
        pri("path: ${info.path ?? 'null'}");
      }
    } catch (error, stack) {
      pri("ERROR: $error");
      pri("STACKTRACE: $stack");
    }

  }

  void _togglePlayPause() {
    pri(" ---------- VIDEO PLAY/PAUSE ======");
    playPauseNotifier.toggle(_isPlaying);
    setState(() {
      _isPlaying ? player.pause() : player.play();
    });
  }

  void _showOverlayWithTimeout() {
    setState(() {
      if (_isAudioSelectionVisisble || _isSubtitleSelectionVisible) {
        _isAudioSelectionVisisble = false;
        _isSubtitleSelectionVisible = false;
        return;
      }
      if (screenLockMode) {
        return;
      }
      _showOverlay = !_showOverlay;
      // if (_showOverlay) {
      //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
      // } else {
      // }
    });
  }

  void _showSystemUI() {
  }

  void _skipVideo(double distance) {
    final currentPosition = player.state.position;
    final skip = Duration(seconds: (distance / 10).round());
    final newPosition = currentPosition + skip;

    if (newPosition > Duration.zero && newPosition < player.state.duration) {
      player.seek(newPosition);
      setState(() {
        _swipwSkipeMessage = 'Skipped ${skip.inSeconds}s';
      });
    }
  }

  setUpPlayer() async {
    try{


      File videoFile = File('/storage/emulated/0/DCIM/Camera/VID_20241122_110548.mp4');
      print("File existance ------------------: ${await videoFile.exists()}");  // true or false




      player = Player();
      mediakit_controller = VideoController(player);
      await player.setSubtitleTrack(SubtitleTrack("-1", '', ''));
      pri('------------ SUBTITLE STREAM ${await player.stream.subtitle} ----------');
      await player.open(Media(widget.videoPath));
      await fetchAudioTrackAndSubtitle();
      FlutterVolumeController.updateShowSystemUI(true);

      player.streams.playing.listen((playing) {
        setState(() {
          _isPlaying = playing;
          playPauseNotifier.toggle(!_isPlaying);
        });
      });

      _positionUpdateTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        setState(() {});
      });
    }catch(er){
      Fluttertoast.showToast(msg: 'Setup Palyer: ${er}');
    }

  }

  Future<void> fetchAudioTrackAndSubtitle() async {
    try {
      pri('------------ fetching tracks & Subtitles ---------------');

      final tracks = await player.state.tracks;
      final audioList = tracks.audio
          .where((track) => track.title != null && track.language != null)
          .toList();

      final sub = player.state.tracks.subtitle
          .where((track) => track.language != null || track.title != null)
          .toList();
      pri('----- Subtitles: ${sub} -----------');
      pri('--------- AUDIO TRAKCS: ${audioList} -------');
      if (true || audioList.isNotEmpty) {
        _audioList = audioList;
        setState(() {
          if(audioList.isNotEmpty)
          currentAudioTrackNotifier =
              CurrentAudioTrackNotifier(audioList.first);
        });
      }
      if (true || sub.isNotEmpty) {
        _subtitles = sub;
        setState(() {
          if(sub.isNotEmpty)
          currentSubtitleNotifier = CurrentSubtitleNotifier(sub.first);
        });
      }
    } catch (error) {
      pri('--------------Error fetching tracks & Subtitles: ${error}. -----------');
      Fluttertoast.showToast(msg: 'Teact Subtitle finding error');
    }
    setState(() {
      _isReadyToPlay = false;
      pri("------- Starting the Player -----------");
    });
  }

  getOrentationIcon() {
    if (Orientation.portrait == _currentOrientation) {
      return Icons.crop_landscape;
    } else {
      return Icons.crop_portrait;
    }
  }

  void captureScreenshot(BuildContext context) async {
    if (_showOverlay) {
      setState(() async {
        _showOverlay = false;
        await Future.delayed(Duration(milliseconds: 300));
      });
    }
    final image = await screenshotController.capture();
    if (image != null) {
      pri("------------ Captured Image: ${image} ---------");
      // Handle the screenshot image (e.g., save it or share it)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ), // BoxDecoration
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Image.memory(image)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6)), // Padding
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.blue.withOpacity(
                                    0.5); // Wave animation color on click
                              }
                              return null; // Defer to the default
                            },
                          ),
                          elevation: MaterialStateProperty.all(2), // Elevation
                          backgroundColor: MaterialStateProperty.all(
                              Colors.blue), // Button color
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                          ),
                        ),
                        child: Text('Save',
                            style: GoogleFonts.manuale(color: Colors.white))),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ), // ElevatedButton (Cancel)
                  ],
                ), // Row
              ],
            ), // Column
          ), // Container
        ), // AlertDialog
      );
    } else {
      pri("----------------No Captured Image -------- ");
    }
  }

  void switchVideoAspect() {
    setState(() {
      screenFitModeNotifier = (screenFitModeNotifier % 4) + 1;
      pri("-------- Change Video Fitting ---------");
    });
    Fluttertoast.showToast(msg: 'Changed: ${screenFitModeNotifier}');
  }

  void _showEyeIntencity() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.7),
          title: Text('Eye Protection '),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Swipe up and down to adjust intensity:'),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Slider(
                    value: _intensityEye,
                    min: 0.0,
                    max: 0.5,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _intensityEye = value;
                      });
                      // Update parent state
                      this.setState(() {
                        _intensityEye = value;
                      });
                      print(_intensityEye.toString());
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showVideoSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.black.withOpacity(0.7),
          title: Text(
            'Video Speed',
            style: GoogleFonts.aboreto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _intensityVideoSpeed,
                    min: 0.5,
                    max: 5.0,
                    divisions: 45, // Increased for more precision
                    onChanged: (value) {
                      setState(() {
                        _intensityVideoSpeed = value;
                        player.setRate(_intensityVideoSpeed);
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${_intensityVideoSpeed.toStringAsFixed(1)}x",
                    style: GoogleFonts.acme(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _intensityVideoSpeed = 1.0;
                  player.setRate(1.0);
                  Navigator.of(context).pop();
                });
              },
              child: Text(
                'Reset',
                style: TextStyle(color: Colors.purple),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final volumeConHeight = max(MediaQuery.of(context).size.width * 0.2, 150.0);
    bool detailsShow = false;

    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    if (_isReadyToPlay) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        body: GestureDetector(
          onTap: () {
            _showOverlayWithTimeout();
          },
          onDoubleTap: () {
            if (!screenLockMode) _togglePlayPause();
          },
          onHorizontalDragUpdate: (details) {
            if (!screenLockMode) {
              setState(() {
                if (!_skipMessageVisible) {
                  _skipMessageVisible = true;
                }
                _swipeDistance += details.primaryDelta!;
                _swipwSkipeMessage = '[${(_swipeDistance / 10).round()}s]';
              });
            }
          },
          onHorizontalDragEnd: (details) {
            if (!screenLockMode) {
              _skipVideo(_swipeDistance);
              Timer(Duration(milliseconds: 500), () {
                setState(() {
                  _skipMessageVisible = false;
                });
              });
              setState(() {
                _swipeDistance = 0;
              });
            }
          },
          child: AnimatedContainer(
            color: Colors.orange,
            duration: Duration(milliseconds: 300),
            child: Screenshot(
              controller: screenshotController,
              child: Stack(
                children: [

                  // Background Video
                  Positioned.fill(
                    child: InkWell(
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            Video(
                              fit: BoxFit.fill,
                              controller: mediakit_controller,
                              // filterQuality: FilterQuality.high,
                            ),
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaY: 100,sigmaX: 100),
                              child: Container(color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(
                                  milliseconds: durationMilliSecondControl),
                              color: Colors.amber.withOpacity(
                                  _intensityEye), // Adjust the color and opacity for the eye protection filter
                            ),
                            Center(
                                child: AnimatedContainer(
                                  height: screenFitModeNotifier == 1
                                      ? (videoHeight! / videoWidth!) * screenWidth
                                      : screenFitModeNotifier == 2
                                      ? (9.0 / 16.0) * screenWidth
                                      : screenFitModeNotifier == 3
                                      ? (3.0 / 4.0) * screenWidth
                                      : videoHeight as double, // Default height if none of the values match

                                  width: screenFitModeNotifier == 1
                                      ? (videoWidth! / videoHeight!) * screenHeight
                                      : screenFitModeNotifier == 2
                                      ? (16.0 / 9.0) * screenHeight
                                      : screenFitModeNotifier == 3
                                      ? (4.0 / 3.0) * screenHeight
                                      : videoWidth as double,
                                  // height: screenFitModeNotifier ? (videoHeight!/videoWidth!) * screenWidth : screenHeight ,
                                  // width: screenFitModeNotifier ? (videoWidth!/videoHeight!) * screenHeight : screenWidth,
                                  duration: Duration(
                                      milliseconds: durationMilliSecondControl),
                                  child: Stack(
                                    children: [
                                      Video(
                                        fit: BoxFit.fill,
                                        controller: mediakit_controller,
                                        subtitleViewConfiguration:
                                        SubtitleViewConfiguration(
                                          padding: EdgeInsets.all(16),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              backgroundColor:
                                              Colors.black.withOpacity(0.8),
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        controls: null,
                                      ),
                                      AnimatedContainer(
                                        duration: Duration(
                                            milliseconds: durationMilliSecondControl),
                                        color: Colors.amber.withOpacity(
                                            _intensityEye), // Adjust the color and opacity for the eye protection filter
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),

                  //VolumeArea - Screen Orintation Area
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (!screenLockMode)
                          setState(() {
                            _skipMessageVisible = true;
                            _skipVideo(100);
                            Timer(Duration(milliseconds: 500), () {
                              setState(() {
                                _skipMessageVisible = false;
                              });
                            });
                          });
                      },
                      onTap: () {
                        _showOverlayWithTimeout();
                      },
                      onVerticalDragUpdate: (details) {
                        if (!screenLockMode)
                          setState(() {
                            if (!_volumeVisible) {
                              _volumeVisible = true;
                            }

                            if (details.primaryDelta! < 0) {
                              _swipeVolumeDistance += 0.8; // Swipe up
                            } else {
                              _swipeVolumeDistance -= 0.8; // Swipe down
                            }

                            _swipeVolumeDistance =
                                _swipeVolumeDistance.clamp(0, 100).toDouble();
                            player.setVolume(_swipeVolumeDistance);
                            print(_swipeVolumeDistance);
                          });
                      },
                      onVerticalDragEnd: (details) {
                        if (!screenLockMode)
                          setState(() {
                            _volumeVisible = false;
                            _brightNessVisible = false;
                            Fluttertoast.showToast(
                                msg: 'Volume/Brightness adjustment ended');
                          });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: MediaQuery.of(context).size.height,
                        padding: EdgeInsets.only(right: 16),
                        color: Colors.transparent,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _showOverlay ? 1 : 0,
                                duration: Duration(milliseconds: durationMilliSecondControl),
                                child: Material(
                                  color: Colors.black.withOpacity(0.8), // Background color with opacity
                                  shape: CircleBorder(),
                                  child: IconButton(
                                    onPressed: () {
                                      if (_showOverlay) {
                                        if (_currentOrientation == Orientation.landscape) {
                                          setState(() {
                                            SystemChrome.setPreferredOrientations([
                                              DeviceOrientation.portraitUp,
                                              DeviceOrientation.portraitDown,
                                            ]);
                                            _currentOrientation = Orientation.portrait;
                                          });
                                        } else {
                                          setState(() {
                                            SystemChrome.setPreferredOrientations([
                                              DeviceOrientation.landscapeLeft,
                                              DeviceOrientation.landscapeRight,
                                            ]);
                                            _currentOrientation = Orientation.landscape;
                                          });
                                        }
                                        pri(
                                            "------------ Orientation Change to ${_currentOrientation} ------------");
                                      } else {
                                        _showOverlayWithTimeout();
                                      }
                                    },
                                    icon: Icon(
                                      getOrentationIcon(),
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: screenHeight * 0.02,
                              ),
                              AnimatedOpacity(
                                opacity: _showOverlay || screenLockMode ? 1 : 0,
                                duration: Duration(milliseconds: durationMilliSecondControl),
                                child: Material(
                                  color: Colors.black.withOpacity(0.8), // Background color with opacity
                                  shape: CircleBorder(),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showOverlay = false;
                                        screenLockMode = !screenLockMode;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //BrightNess Aread
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (!screenLockMode)
                          setState(() {
                            _skipMessageVisible = true;
                            _skipVideo(-100);
                            Timer(Duration(milliseconds: 500), () {
                              setState(() {
                                _skipMessageVisible = false;
                              });
                            });
                          });
                      },
                      onTap: () {
                        _showOverlayWithTimeout();
                      },
                      onVerticalDragUpdate: (details) {
                        if (!screenLockMode)
                          setState(() {
                            // Get the screen width
                            double screenWidth = MediaQuery.of(context).size.width;

                            // Get the global position of the swipe
                            RenderBox renderBox = context.findRenderObject() as RenderBox;
                            Offset localPosition =
                            renderBox.globalToLocal(details.globalPosition);

                            // Check if the swipe is on the right side of the screen
                            if (!_brightNessVisible) {
                              _brightNessVisible = true;
                            }

                            // Increase or decrease brightness based on swipe direction
                            if (details.primaryDelta! < 0) {
                              _swipeBrightDistance += 0.8; // Swipe up
                            } else {
                              _swipeBrightDistance -= 0.8; // Swipe down
                            }

                            // Clamp the value between 0 and 100
                            _swipeBrightDistance =
                                _swipeBrightDistance.clamp(0, 100).toDouble();
                            ScreenBrightness().setScreenBrightness(
                                _swipeBrightDistance / 100);
                          });
                      },
                      onVerticalDragEnd: (details) {
                        if (!screenLockMode)
                          setState(() {
                            _volumeVisible = false;
                            _brightNessVisible = false;
                            Fluttertoast.showToast(
                                msg: 'Volume/Brightness adjustment ended');
                          });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: MediaQuery.of(context).size.height,
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _showOverlay ? 1 : 0,
                                duration: Duration(milliseconds: durationMilliSecondControl),
                                child: Material(
                                  color: Colors.black.withOpacity(0.8), // Background color with opacity
                                  shape: CircleBorder(),
                                  child: InkWell(
                                    onLongPress: (){
                                      setState(() {
                                        _showOverlay = false;
                                        _showEyeIntencity();
                                      });
                                    },
                                    child: IconButton(
                                      onPressed: () {
                                        if (_showOverlay) {
                                          if (!_isEyeOpen) {
                                            setState(() {
                                              _isEyeOpen = true;
                                              if (_intensityEye <= 0.0) {
                                                _intensityEye = 0.2;
                                              }
                                            });
                                          } else {
                                            setState(() {
                                              _isEyeOpen = false;
                                              _intensityEye = 0.0;
                                            });
                                          }
                                        } else {
                                          _showOverlayWithTimeout();
                                        }
                                      },
                                      icon: Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: _intensityEye > 0.0 ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: screenHeight * 0.02,
                              ),
                              AnimatedOpacity(
                                opacity: _showOverlay ? 1 : 0,
                                duration: Duration(milliseconds: durationMilliSecondControl),
                                child: Material(
                                  color: Colors.black.withOpacity(0.8), // Background color with opacity
                                  shape: CircleBorder(),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showOverlay = false;
                                        _showVideoSpeedDialog();
                                      });
                                    },
                                    icon: Text(
                                      "${_intensityVideoSpeed.toStringAsFixed(1)}x",
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // PlayPause
                  Align(
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1 : 0,
                        duration: Duration(milliseconds: 200),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              if (_showOverlay) {
                                playPauseNotifier.toggle(!_isPlaying);
                                _togglePlayPause();
                              } else {
                                setState(() {
                                  _showOverlay = !_showOverlay;
                                });
                              }
                            },
                            child: PlayPauseButton(
                              animationPath: 'assets/Lot/play_pause_lot.json',
                              duration: Duration(milliseconds: 2000),
                              width: 800.0,
                              height: 800.0,
                              notifier: playPauseNotifier,
                              isPlay: _isPlaying,
                            ),
                          ),
                        ),
                      )),

                  //Details
                  AnimatedPositioned(
                    top: _showOverlay ? 0 : -(MediaQuery.of(context).padding.top + kToolbarHeight),
                    right: 0,
                    left: 0,
                    duration: Duration(milliseconds: 200),
                    child: InkWell(
                      onTap: () {
                        Fluttertoast.showToast(msg: 'Details Clicked');
                        setState(() {
                          detailsShow = !detailsShow;
                        });
                      },
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Container(
                          color: PrimaryBackgroundColor,
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_ios_new, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: TextStyle(color: Colors.white, fontSize: 19),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        widget.videoPath,
                                        style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VideoInfoIcon(videoPath: widget.videoPath, context: context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //Bottom Container
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 200),
                    bottom: _showOverlay
                        ? 0
                        : -(MediaQuery.of(context).padding.bottom +
                            100), // Adjust 100 to the height of your bottom container
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showOverlay ? 1 : 0,
                      duration: Duration(milliseconds: 200),
                      child: IntrinsicHeight(
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Slider(
                                onChangeEnd: (value) {
                                  player.seek(
                                      Duration(milliseconds: value.toInt()));
                                },
                                value: player.state.position.inMilliseconds
                                    .toDouble(),
                                min: 0.0,
                                max: player.state.duration.inMilliseconds
                                    .toDouble(),
                                onChanged: (value) {},
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 24, right: 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_formatDuration(player.state.position)} / ${_formatDuration(player.state.duration)}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Expanded(
                                      child:
                                      MediaQuery.of(context).orientation == Orientation.landscape ?
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                              onTap: () => {
                                                    // Vibrate.vibrate(),
                                                    player.setVolume(0),
                                                    Fluttertoast.showToast(
                                                        msg: 'Mute'),
                                                    pri('------ VIDEO MUTED --------')
                                                  },
                                              child: LabelIcon(
                                                icon: Icons.volume_mute,
                                              )),
                                          InkWell(
                                              onTap: () => {
                                                    setState(() {
                                                      _isAudioSelectionVisisble =
                                                          true;
                                                      if (_showOverlay) {
                                                        _showOverlay = false;
                                                      }
                                                    }),
                                                    pri('------- VIDEO TRACK SELECTION ---------')
                                                  },
                                              child: LabelIcon(
                                                icon: Icons.audio_file_sharp,
                                              )),
                                          InkWell(
                                              onTap: () => {
                                                    setState(() {
                                                      _isSubtitleSelectionVisible =
                                                          true;
                                                      if (_showOverlay) {
                                                        _showOverlay = false;
                                                      }
                                                    }),
                                                    pri('------- VIDEO SUBTITLE SELECTION ---------')
                                                  },
                                              child: LabelIcon(
                                                icon:
                                                    Icons.closed_caption_outlined,
                                              )),
                                          InkWell(
                                              onTap: () => {
                                                    Fluttertoast.showToast(
                                                        msg: "asddddddddddd"),
                                                    captureScreenshot(context)
                                                  },
                                              child: LabelIcon(
                                                icon: Icons
                                                    .screenshot_monitor_sharp,
                                              )),
                                          InkWell(
                                              onTap: () => {switchVideoAspect()},
                                              child: LabelIcon(
                                                icon: Icons.crop,
                                              )),
                                        ],
                                      ) : SingleChildScrollView(
                                        physics: BouncingScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                                onTap: () => {
                                                  //Vibrate.vibrate(),
                                                  player.setVolume(0),
                                                  Fluttertoast.showToast(
                                                      msg: 'Mute'),
                                                  pri('------ VIDEO MUTED --------')
                                                },
                                                child: LabelIcon(
                                                  icon: Icons.volume_mute,
                                                )),
                                            InkWell(
                                                onTap: () => {
                                                  setState(() {
                                                    _isAudioSelectionVisisble =
                                                    true;
                                                    if (_showOverlay) {
                                                      _showOverlay = false;
                                                    }
                                                  }),
                                                  pri('------- VIDEO TRACK SELECTION ---------')
                                                },
                                                child: LabelIcon(
                                                  icon: Icons.audio_file_sharp,
                                                )),
                                            InkWell(
                                                onTap: () => {
                                                  setState(() {
                                                    _isSubtitleSelectionVisible =
                                                    true;
                                                    if (_showOverlay) {
                                                      _showOverlay = false;
                                                    }
                                                  }),
                                                  pri('------- VIDEO SUBTITLE SELECTION ---------')
                                                },
                                                child: LabelIcon(
                                                  icon:
                                                  Icons.closed_caption_outlined,
                                                )),
                                            InkWell(
                                                onTap: () => {
                                                  Fluttertoast.showToast(
                                                      msg: "asddddddddddd"),
                                                  captureScreenshot(context)
                                                },
                                                child: LabelIcon(
                                                  icon: Icons
                                                      .screenshot_monitor_sharp,
                                                )),
                                            InkWell(
                                                onTap: () => {switchVideoAspect()},
                                                child: LabelIcon(
                                                  icon: Icons.crop,
                                                )),
                                          ],
                                        ),
                                      )
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //Skip Video Message
                  Align(
                    alignment: Alignment.topCenter,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 100),
                      opacity: _skipMessageVisible ? 1 : 0,
                      child: AnimatedContainer(
                        duration: Duration(
                            milliseconds: 300), // Duration for position change-
                        transform: Matrix4.translationValues(
                          0.0,
                          _skipMessageVisible
                              ? 50.0
                              : -50.0, // Adjust the Y offset as needed
                          0.0,
                        ),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _swipwSkipeMessage,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  //Swipe Volume Bar
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    top: _volumeVisible ? 20 : -50,
                    right: 0,
                    left: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: IntrinsicWidth(
                        child: Container(
                          padding: EdgeInsets.only(top: 12, bottom: 12, left: 18, right: 24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _swipeVolumeDistance <= 0.0 ? Icons.volume_mute : Icons.volume_down,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Container(
                                  width: volumeConHeight,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Container(
                                          color: Colors.grey,
                                          width: volumeConHeight * (_swipeVolumeDistance / 100),
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
                    ),
                  ),

                  //Swipe Brightness bar
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    top: _brightNessVisible ? 20 : -50,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: IntrinsicWidth(
                        child: Container(
                          padding:
                              EdgeInsets.only(left: 18, right: 24,top: 12,bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(
                                _swipeBrightDistance == 0
                                    ? Icons.brightness_low
                                    : (_swipeBrightDistance > 0 && _swipeBrightDistance <= 75)
                                    ? Icons.brightness_medium
                                    : (_swipeBrightDistance > 75 && _swipeBrightDistance <= 100)
                                    ? Icons.brightness_high
                                    : Icons.brightness_auto, // default case for out of range values
                              color: Colors.orangeAccent,
                              ),

                              SizedBox(width: 10,),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: volumeConHeight,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Container(
                                          color: Colors.deepOrangeAccent,
                                          width: volumeConHeight *
                                              (_swipeBrightDistance / 100),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                 // Audio Selection Dialog
                  GestureDetector(
                    onTap: () => setState(() {
                      _isAudioSelectionVisisble = false;
                    }),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        opacity: _isAudioSelectionVisisble ? 1 : 0,
                        duration:
                            Duration(milliseconds: durationMilliSecondControl),
                        child: AnimatedContainer(
                            transform: Matrix4.translationValues(
                                0, _isAudioSelectionVisisble ? 10 : -500, 0),
                            duration: Duration(milliseconds: 300),
                            child: AudioTrackSelectionDialog(
                              audioList: _audioList,
                              onClick: (AudioTrack track) {
                                currentAudioTrackNotifier?.switchTrack(track);
                                player.setAudioTrack(track);
                                pri('----------- VIDEO TRACK SELECTED ${track} -----------');
                              },
                            )),
                      ),
                    ),
                  ),

                  //Subtitle Selection Dialog
                  GestureDetector(
                    onTap: () => setState(() {
                      _isSubtitleSelectionVisible = false;
                    }),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        opacity: _isSubtitleSelectionVisible ? 1 : 0,
                        duration:
                            Duration(milliseconds: durationMilliSecondControl),
                        child: AnimatedContainer(
                            transform: Matrix4.translationValues(
                                0, _isSubtitleSelectionVisible ? 10 : -500, 0),
                            duration: Duration(milliseconds: 300),
                            child: SubtitleSelectionDialog(
                              audioList: _subtitles,
                              onClick: (SubtitleTrack track) {
                                player.setSubtitleTrack(track);
                                pri('----------- VIDEO SUBTITLE SELECTED ${track} -----------');
                              },
                            )),
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}

class LabelIcon extends StatelessWidget {
  const LabelIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.8)),
      child: Icon(
        icon,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }
}
