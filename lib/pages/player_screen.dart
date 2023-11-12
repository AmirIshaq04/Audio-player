import 'package:appish/const/list.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appish/widgets/models.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:ringtone_set/ringtone_set.dart';

class PlayerScreen extends StatefulWidget {
  final int index;
  PlayerScreen({required this.index, Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? ringtonePath;
  bool isSongCompleted = false;
  bool isRepeating = false; //
  int selectedIndex = -1; //
  bool isactive = false; //
  int currentlyplayingIndex = -1; //setting index
  double sliderValue = 0.0; //
  Duration? storedPosition; //
  List<String> favoriteAudioPaths = []; //
  late List<bool> isFavorite; //
  late List<List<IconData>> iconlist; //
  late List<bool> isplaying; //
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer(); //
  // play audio function
  //combined both for retrieved data & repetition of song

  Future<void> playAudio(int index) async {
    await audioPlayer.open(Audio(data!.audioPaths));
    audioPlayer.realtimePlayingInfos.listen((info) {
      if (info != null) {
        final duration = info.duration;
        final currentPosition = info.currentPosition;
        if (duration != null && currentPosition != null) {
          setState(() {
            currentPosition.inMilliseconds / duration.inMilliseconds;
          });
        }
      }
    });
  }

  void repeatMode() {
    setState(() {
      isRepeating = !isRepeating;
    });
    audioPlayer.setLoopMode(isRepeating ? LoopMode.single : LoopMode.none);
  }

  //stop Audio function
  Future<void> stopAudio() async {
    await audioPlayer.stop();
  }

  ///creating method for accessing path of favorite Audio
  Future<void> playAudioFromPath() async {
    await audioPlayer.open(Audio('asset/audios/song.mp3'));
  }

  //load method for shared preferences
  Future<void> loadFavoriteAudioPaths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? storedPaths = prefs.getStringList('favoritePaths');
    if (storedPaths != null) {
      setState(() {
        favoriteAudioPaths = storedPaths;
        isFavorite = List.generate(
          firstlist.length,
          (index) => favoriteAudioPaths.contains(firstlist[index].audioPaths),
        );
      });
    } else {
      setState(() {
        isFavorite = List.generate(firstlist.length, (index) => false);
      });
    }
  }

  //savind Data
  Future<void> saveFavoriteAudioPaths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favoritePaths', favoriteAudioPaths);
  }

  /////////////////////////////functions for Audioplayback
  //  Previous song method
  void seekaudio(double value) {
    final info = audioPlayer.realtimePlayingInfos.value;
    final duration = info.duration;
    if (duration != null) {
      final newPosition = (value * duration.inMilliseconds).round();
      audioPlayer.seek(Duration(milliseconds: newPosition));
    }
  }

  void playPreviousSong() {
    audioPlayer.previous();
  }

  ////
  void playNextSong() {
    audioPlayer.next();
  }

  Future<void> playSong() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPositionMiliseconds = prefs.getInt('storedPosition') ?? 0;
    storedPosition = Duration(milliseconds: storedPositionMiliseconds);
    //print(storedPosition);
    if (storedPosition != null) {
      audioPlayer.seek(storedPosition!);

      audioPlayer.play();
    } else {
      audioPlayer.play();
    }
  }

  Future<void> pausesong() async {
    audioPlayer.pause();
    storedPosition = audioPlayer.currentPosition.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('storedPosition', storedPosition?.inMilliseconds ?? 0);
  }

  ///////function to toggle playPuase
  void togglePlayPause() {
    if (audioPlayer.isPlaying.value) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
    setState(() {});
  }

  Data? data;
  @override
  void initState() {
    super.initState();
    data = firstlist[widget.index];
    isplaying = List.generate(firstlist.length, (index) => false);
    isFavorite = List.generate(firstlist.length, (index) => false);
    //loadFavoriteAudioPaths(); //initialzation of load method in initState
    WidgetsBinding.instance?.addObserver(this);
    storedPosition = Duration.zero;

    //adding a listener to guade if the song has completed & change icon
    audioPlayer = AssetsAudioPlayer.withId('0')
      ..realtimePlayingInfos.listen((info) {
        if (info != null) {
          final duration = info.duration;
          final currentPosition = info.currentPosition;
          if (duration != null && currentPosition != null) {
            setState(() {
              sliderValue =
                  currentPosition.inMilliseconds / duration.inMilliseconds;
            });
          }
        }
      })
      ..playlistAudioFinished.listen((event) {
        setState(() {
          isSongCompleted = true;
        });
      })
      ..play();

/////////

    audioPlayer.realtimePlayingInfos.listen((info) {
      if (info != null) {
        final duration = info.duration;
        final currentPosition = info.currentPosition;
        if (duration != null && currentPosition != null) {
          setState(() {
            sliderValue =
                currentPosition.inMilliseconds / duration.inMilliseconds;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (audioPlayer.isPlaying.value) {
        pausesong();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!audioPlayer.isPlaying.value) {
        pausesong();
      }
    }
  }

//  Future<void> selectRingtone(BuildContext context) async {
//   bool isRingtoneSet = false;

//   try {
//     isRingtoneSet = await RingtoneSet.setRingtone('asset/audios/song.mp3');
//   } catch (e) {
//     print('Error setting ringtone: $e');
//   }

//   if (isRingtoneSet) {
//     print('Ringtone set successfully: $isRingtoneSet');
//     ringtonePath = 'D:/Workspace_flutter/appish/asset/audios/song.mp3';

//     // Create the URI here
//     Uri uri = Uri.file('asset/audios/song.mp3');

//     // Now you can use the 'uri' variable as needed
//     // ...

//   } else {
//     print('Failed to set ringtone');
//   }
// }

//   //method for alarm
//   Future<void> scheuleAlarm(
//     int alarmId,
//     DateTime alarmTime,
//   ) async {
//     try {
//       bool isringtoneSet =
//           await RingtoneSet.setRingtone('asset/audios/song.mp3');
//       if (isringtoneSet) {
//         await AndroidAlarmManager.oneShot(alarmTime as Duration, alarmId, () {
//           print('Alarm triggered for for Id :$alarmId');

//         },exact: true,
//         wakeup: true,
//         );
//       }
//     } on PlatformException catch(e)  {
//       print('Error setting message:${e.message}');
//     }
//   }

// Future<void> playSelectedRingtone(String ringtoneUri) async {
//   AudioPlayer audioPlayer = AudioPlayer();

//   try {
//     await audioPlayer.play(ringtoneUri, isLocal: true);

//     audioPlayer.onPlayerCompletion.listen((event) {
//       // Add logic to handle completion (e.g., stop the player or update UI)
//     });
//   } catch (e) {
//     // Handle any exceptions that may occur during playback
//     print('Error playing ringtone: $e');
//   }
// }
  Future<void> selectRingtone(BuildContext context) async {
    try {
      bool isRingtoneSet =
          await RingtoneSet.setRingtone('asset/audios/song.mp3');
      if (isRingtoneSet) {
        print('Ringtone set successfully: $isRingtoneSet');
      } else {
        print('Failed to set ringtone');
      }
    } catch (e) {
      print('Error setting ringtone: $e');
    }
  }

  Future<void> setRingtoneAndScheduleAlarm() async {
    try {
      bool isRingtoneSet =
          await RingtoneSet.setRingtone('asset/audios/song.mp3');
      if (isRingtoneSet) {
        print('Ringtone set successfully: $isRingtoneSet');

        // Schedule the alarm after setting the ringtone
        await AndroidAlarmManager.oneShot(
          const Duration(seconds: 10), // Set the delay for the alarm
          0, // Unique alarm ID
          () {
            print('Alarm triggered!');
            // Add logic to perform actions when the alarm is triggered
          },
          exact: true,
          wakeup: true,
        );
      } else {
        print('Failed to set ringtone');
      }
    } catch (e) {
      print('Error setting ringtone: $e');
    }
  }

  Widget build(BuildContext context) {
    Data data = firstlist[widget.index];

    return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          backgroundColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              shape: Border(
                  bottom: BorderSide(
                color: Colors.grey,
              )),
              color: Colors.greenAccent,
              itemBuilder: (BuildContext context) {
                return {
                  'Set as Alarm',
                  'Set as Ringtone',
                  'Set as Notification'
                }.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              onSelected: (String choice) async {
                switch (choice) {
                  case 'Set as Alarm':
                    await setRingtoneAndScheduleAlarm();
                    break;
                  case 'Set as Ringtone':
                    print('Set as Ringtone');
                    break;
                  case 'Set as Notification':
                    print('Set as Notification');
                    break;
                }
              },
            ),
          ],
        ),
        body: Container(
            child: Column(children: [
          Lottie.asset('asset/images/lottie.json', height: 150),
          Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Gap(120),
                    Text(
                      data.text,
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10.h,
                ),
                //seekbar
                StreamBuilder<RealtimePlayingInfos>(
                  stream: audioPlayer.realtimePlayingInfos,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final info = snapshot.data;
                      final duration = info!.duration;
                      final currentPosition = info.currentPosition;

                      if (duration != null && currentPosition != null) {
                        double playbackPosition =
                            currentPosition.inMilliseconds /
                                duration.inMilliseconds;
                        if (playbackPosition.isNaN) {
                          playbackPosition = 0.0;
                        } else {
                          playbackPosition = playbackPosition.clamp(0.0, 1.0);
                        }
                        return Slider(
                          thumbColor: Colors.black54,
                          activeColor: Colors.black87,
                          value: playbackPosition,
                          onChanged: (double value) {
                            final realDuration =
                                audioPlayer.current.value!.audio.duration;
                            int newPosition =
                                (value * realDuration.inMilliseconds).round();
                            audioPlayer
                                .seek(Duration(milliseconds: newPosition));
                            setState(() {
                              sliderValue = value;
                            });
                          },
                        );
                      }
                    }
                    return const Slider(
                      value: 0.0,
                      onChanged: null,
                      activeColor: Colors.black87,
                    );
                  },
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 90.w,
                    ),
                    IconButton(
                        onPressed: () {
                          playSong();
                        },
                        icon: Icon(Icons.skip_previous)),
                    IconButton(
                      onPressed: () {
                        if (isSongCompleted) {
                          // Logic when song is completed
                          setState(() {
                            isplaying[widget.index] =
                                false; // Reset the play state
                            isSongCompleted =
                                false; // Reset the completion state
                          });
                          playAudio(widget.index);
                        } else {
                          for (int i = 0; i < isplaying.length; i++) {
                            if (i != widget.index && isplaying[i]) {
                              audioPlayer.pause();
                              isplaying[i] = false;
                            }
                          }
                          if (isplaying[widget.index]) {
                            pausesong();
                          } else {
                            playAudio(widget.index);
                            playSong();
                          }
                          isplaying[widget.index] = !isplaying[widget.index];
                          setState(() {});
                        }
                      },
                      icon: Icon(
                        isSongCompleted
                            ? Icons
                                .play_arrow // Change this to the appropriate icon for completed state
                            : (isplaying[widget.index] ||
                                    audioPlayer.isPlaying.value
                                ? Icons.pause
                                : Icons.play_arrow),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          pausesong();
                        },
                        icon: Icon(Icons.skip_next)),
                    IconButton(
                      onPressed: () {
                        repeatMode();
                      },
                      icon: Icon(
                        isRepeating ? Icons.repeat_one : Icons.repeat,
                        color: isRepeating ? Colors.black : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ])));
  }
}
