// import 'package:animations/animations.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:marquee/marquee.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:rxdart/rxdart.dart';
//
// class MusicPage extends StatelessWidget {
//   MusicPage({Key? key}) : super(key: key);
//
//   List<SongModel> songs = [];
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   final ValueNotifier<AudioPlayer> _audioPlayer = ValueNotifier(AudioPlayer());
//   final ValueNotifier<SongModel?> _currentSongNotifier = ValueNotifier(null);
//
//   Future<List<SongModel>> _fetchSongs() async {
//     return await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//     );
//   }
//
//   void _playSong(SongModel song) async {
//     try {
//       await _audioPlayer.value.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
//       _audioPlayer.value.play();
//       _currentSongNotifier.value = song;
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error playing song: $e');
//     }
//   }
//
//   Future<void> _nextSong() async {
//     Fluttertoast.showToast(msg: 'Next clicked');
//     if (songs.isEmpty) {
//       songs = await _fetchSongs();
//     }
//     var index = songs.indexOf(_currentSongNotifier.value!);
//     if (index == songs.length - 1) {
//       _currentSongNotifier.value = songs.first;
//     } else {
//       _currentSongNotifier.value = songs[index + 1];
//     }
//     await _audioPlayer.value.setAudioSource(AudioSource.uri(Uri.parse(_currentSongNotifier.value!.uri!)));
//     _audioPlayer.value.play();
//   }
//
//   void _prevSong() async {
//     Fluttertoast.showToast(msg: 'Prev clicked');
//     if (songs.isEmpty) {
//       songs = await _fetchSongs();
//     }
//     var index = songs.indexOf(_currentSongNotifier.value!);
//     if (index == 0) {
//       _currentSongNotifier.value = songs.last;
//     } else {
//       _currentSongNotifier.value = songs[index - 1];
//     }
//     await _audioPlayer.value.setAudioSource(AudioSource.uri(Uri.parse(_currentSongNotifier.value!.uri!)));
//     _audioPlayer.value.play();
//   }
//
//   SongModel? getCurrentSongModel(AudioPlayer audioPlayer) {
//     return audioPlayer.sequenceState?.currentSource?.tag as SongModel?;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Music Player'),
//       ),
//       body: FutureBuilder<List<SongModel>>(
//         future: _fetchSongs(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No music found'));
//           } else {
//             songs = snapshot.data!;
//             return Stack(
//               children: [
//                 ListView.builder(
//                   itemCount: snapshot.data!.length,
//                   itemBuilder: (context, index) {
//                     SongModel song = snapshot.data![index];
//                     return MusicNode(
//                       isSelected: false,
//                       onTap: () => _playSong(song),
//                       onLongPress: () => Fluttertoast.showToast(msg: 'Long Pressed'),
//                       song: song,
//                       selectionMode: ValueNotifier(false),
//                     );
//                   },
//                 ),
//                 ValueListenableBuilder<SongModel?>(
//                   valueListenable: _currentSongNotifier,
//                   builder: (context, currentSong, child) {
//                     return currentSong != null
//                         ? Positioned(
//                       bottom: 0,
//                       left: 0,
//                       right: 0,
//                       child: OpenContainer(
//                         closedElevation: 1.0,
//                         closedShape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(0),
//                         ),
//                         transitionDuration: Duration(milliseconds: 400),
//                         closedBuilder: (context, openContainer) {
//                           return ValueListenableBuilder(
//                             valueListenable: _audioPlayer,
//                             builder: (BuildContext context, value, Widget? child) {
//                               return MinimizePlayer(
//                                 albumImageId: currentSong.id,
//                                 openContainer: openContainer,
//                                 audioPlayer: _audioPlayer.value,
//                                 songName: currentSong.title,
//                                 singerName: currentSong.artist ?? 'Unknown Artist',
//                               );
//                             },
//                           );
//                         },
//                         openBuilder: (context, closeContainer) {
//                           return FullScreenPlayer(
//                             currentSong: _currentSongNotifier ?? ValueNotifier(currentSong),
//                             albumImageId: currentSong.id,
//                             closeContainer: closeContainer,
//                             audioPlayer: _audioPlayer.value,
//                             songName: currentSong.title,
//                             singerName: currentSong.artist ?? 'Unknown Artist',
//                             onNext: _nextSong,
//                             onPrev: _prevSong,
//                           );
//                         },
//                       ),
//                     )
//                         : SizedBox.shrink();
//                   },
//                 ),
//               ],
//             );
//           }
//         },
//       ),
//     );
//   }
// }
//
// class FullScreenPlayer extends StatelessWidget {
//   final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
//   final VoidCallback closeContainer;
//   final ValueNotifier<SongModel?> currentSong;
//   final AudioPlayer audioPlayer;
//   final int albumImageId;
//   final String songName;
//   final String singerName;
//   final VoidCallback onPrev;
//   final VoidCallback onNext;
//
//
//   FullScreenPlayer({
//     required this.singerName,
//     required this.songName,
//     required this.closeContainer,
//     required this.audioPlayer,
//     required this.albumImageId,
//     required this.onPrev,
//     required this.onNext,
//     required this.currentSong
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder(
//       valueListenable: currentSong,
//       builder: (BuildContext context, value, Widget? child) {
//         return GestureDetector(
//           onVerticalDragUpdate: (details) {
//             final deltaY = details.primaryDelta!;
//             if (deltaY > 5) {
//               closeContainer();
//               Fluttertoast.showToast(msg: 'Value: $deltaY');
//             }
//           },
//           child: Scaffold(
//             appBar: AppBar(
//               leading: IconButton(
//                 icon: Icon(Icons.arrow_downward),
//                 onPressed: closeContainer,
//               ),
//               title: Text('Now Playing'),
//             ),
//             body: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   QueryArtworkWidget(
//                     id: currentSong.value!.id,
//                     artworkHeight: 300,
//                     artworkWidth: 300,
//                     type: ArtworkType.AUDIO,
//                     nullArtworkWidget: Icon(Icons.music_note, size: 300),
//                   ),
//                   SizedBox(height: 20),
//                   Hero(
//                     tag: 'SongName',
//                     child: Text(
//                       songName,
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                   Text(
//                     singerName,
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                   SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.skip_previous),
//                         iconSize: 36,
//                         onPressed: () {
//                           Fluttertoast.showToast(msg: 'Prev');
//                           onPrev();
//                         },
//                       ),
//                       ValueListenableBuilder(
//                         valueListenable: isPlayingNotifier,
//                         builder: (BuildContext context, value, Widget? child) {
//                           return IconButton(
//                             icon: Icon(audioPlayer.playing ? Icons.pause : Icons.play_arrow),
//                             iconSize: 36,
//                             onPressed: () {
//                               isPlayingNotifier.value = audioPlayer.playing;
//                               if (audioPlayer.playing) {
//                                 audioPlayer.pause();
//                               } else {
//                                 audioPlayer.play();
//                               }
//                             },
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.skip_next),
//                         iconSize: 36,
//                         onPressed: () {
//                           Fluttertoast.showToast(msg: 'Next');
//                           onNext();
//                         },
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   StreamBuilder<Duration?>(
//                     stream: audioPlayer.positionStream,
//                     builder: (context, snapshot) {
//                       Duration? position = snapshot.data;
//                       final currentSong = audioPlayer.audioSource?.sequence[audioPlayer.currentIndex!];
//                       return Slider(
//                         value: position?.inSeconds.toDouble() ?? 0.0,
//                         onChanged: (value) {
//                           audioPlayer.seek(Duration(seconds: value.toInt()));
//                         },
//                         min: 0.0,
//                         max: currentSong?.duration?.inSeconds.toDouble() ?? 1.0,
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
//
//
//
// class MinimizePlayer extends StatelessWidget {
//   MinimizePlayer({
//     Key? key,
//     required this.openContainer,
//     required this.singerName,
//     required this.songName,
//     required this.albumImageId,
//     required this.audioPlayer,
//   }) : super(key: key);
//
//   final VoidCallback openContainer;
//   final AudioPlayer audioPlayer;
//   final int albumImageId;
//   final String songName;
//   final String singerName;
//
//
//   late ValueNotifier<bool> _isPlayingNotifier;
//
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     _isPlayingNotifier = ValueNotifier(audioPlayer.playing);
//
//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         openContainer();
//         Fluttertoast.showToast(msg: 'msg');
//       },
//
//       onTap: openContainer,
//       child: Container(
//         color: Colors.blue.shade50,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.only(right: 6),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: QueryArtworkWidget(
//                       artworkHeight: 55,
//                       artworkWidth: 55,
//                       id: albumImageId,
//                       type: ArtworkType.AUDIO,
//                       nullArtworkWidget: Image.network(
//                         'https://via.placeholder.com/50',
//                         height: 60,
//                         width: 60,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8,),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                        Hero(
//                         tag: 'SongName',
//                           child: Text(
//                              songName+'ssssssssssssssssssss',
//                           )
//                       ),
//                     Text(singerName ?? 'Unknown Artist',style: TextStyle(color: Colors.grey,fontSize: 15))
//                   ],
//                 ),
//               ],
//             ),
//             ValueListenableBuilder<bool>(
//               valueListenable: _isPlayingNotifier,
//               builder: (context, isPlaying, _) {
//                 return Container(
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade400,
//                     borderRadius: BorderRadius.circular(50)
//                   ),
//                   child: Row(
//                     children: [
//                   SizedBox(
//                     height: 40,
//                     child: IconButton(
//                     icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
//                     onPressed: () {
//                     isPlaying ? audioPlayer.pause() : audioPlayer.play();
//                     _isPlayingNotifier.value = !isPlaying;
//                     },
//                     ),
//                   ),
//                   SizedBox(
//                     height: 40,
//                     child: IconButton(
//                     icon: Icon(Icons.skip_next,),
//                     onPressed: () {
//                     isPlaying ? audioPlayer.pause() : audioPlayer.play();
//                     _isPlayingNotifier.value = !isPlaying;
//                     },
//                     ),
//                   )
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
// class MusicNode extends StatelessWidget {
//   final bool isSelected;
//   final VoidCallback onTap;
//   final VoidCallback onLongPress;
//   final SongModel song;
//   final ValueNotifier<bool> selectionMode;
//   ValueNotifier<int> noChange = ValueNotifier(20);
//
//   MusicNode({
//     Key? key,
//     required this.isSelected,
//     required this.onTap,
//     required this.onLongPress,
//     required this.song,
//     required this.selectionMode,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<bool>(
//       valueListenable: selectionMode,
//       builder: (BuildContext context, value, Widget? child) {
//         return InkWell(
//           onTap: onTap,
//           onLongPress: onLongPress,
//           child: AnimatedContainer(
//             duration: Duration(milliseconds: 200),
//             margin: EdgeInsets.symmetric(vertical: 2),
//             padding: EdgeInsets.only(
//                 top: 10,
//                 bottom: 10,
//                 right: isSelected ? 15 : 10,
//                 left: isSelected ? 15 : 10),
//             color: isSelected ? Colors.blue.shade100 : Colors.transparent,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Container(
//                     height: 50,
//                     width: 50,
//                     padding: EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: ValueListenableBuilder(
//                       valueListenable: noChange,
//                       builder: (BuildContext context, value, Widget? child) {
//                         return QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: Icon(Icons.music_note, size: 50),
//                         );
//                       },
//                     )),
//                 Expanded(
//                   child: Container(
//                     margin: EdgeInsets.only(left: 16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           song.title,
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         Text(
//                           song.artist ?? 'Unknown Artist',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Text(
//                   Duration(milliseconds: song.duration!)
//                       .toString()
//                       .split('.')
//                       .first,
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
