import 'dart:math';
import 'package:appish/const/list.dart';
import 'package:appish/pages/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int currentlyplayingIndex = -1; //setting index
  double sliderValue = 0.0;
  Duration? storedPosition;
  List<bool> isPlaying = List.filled(firstlist.length, false);
  List<String> favoriteAudioPaths = [];
  late List<bool> isFavorite;
  late List<List<IconData>> iconlist;
  List<bool> isBottomSheetPlaying = List.filled(firstlist.length, false);
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  // play audio function
  Future<void> playAudio(int index) async {
    if (audioPlayer.isPlaying.value) {
      //audioplayer is instance of assestsAudioPlayer
      await audioPlayer
          .stop(); // isPlaying,a property of,tells whether audio playing or not
      setState(() {
        // schedule a rebuild of widgets tree
        isPlaying[currentlyplayingIndex] =
            false; //indicates audio not playing at index -1
      });
    }

    if (currentlyplayingIndex != index) {
      //if index of audio to be played is diff from the currently playing,means different audio should be played
      await audioPlayer.open(
          Audio(firstlist[index].audioPaths), //audioplayer=>opens audio
          autoStart: false,
          showNotification: true);
      setState(() {
        currentlyplayingIndex =
            index; //updates currentPindex to new index, that new song is playing
      });
    }

    await audioPlayer
        .play(); //starts or resume playback of current song,plays audio from current possition
    setState(() {
      isPlaying[index] =
          true; //updates isplaying that audio at specific index is playing, controlls appearance of play/pause
    });
  }

  void onBellIconPressed(int index) {
    //index being passed, tells us that which audio associated with to play
    showAudioPlayerBottomSheet(index);
  }

  //stop Audio function
  Future<void> stopAudio() async {
    await audioPlayer
        .stop(); //stops audio and resets it, that will play from start if we play again
  }

  ///creating method for accessing path of favorite Audio
  Future<void> playAudioFromPath() async {
    await audioPlayer.open(Audio('asset/audios/song.mp3'));
  }

  //load method for shared preferences
  Future<void> loadFavoriteAudioPaths() async {
    final SharedPreferences prefs = await SharedPreferences
        .getInstance(); //getInstance ensured that prefs assigned shaedPreference instance before proceeding with other code
    final List<String>? storedPaths = prefs.getStringList(
        'favoritePaths'); //get list of strings with key 'favoritePaths'
    if (storedPaths != null) {
      setState(() {
        favoriteAudioPaths = storedPaths; //stored goes in favorite
        isFavorite = List.generate(
          firstlist.length,
          (index) => favoriteAudioPaths.contains(firstlist[index].audioPaths),
        ); //generate new list of songs if they are present in the list as audiopaths
      });
    } else {
      setState(() {
        isFavorite =
            List.generate(firstlist.length, (index) => false); //not found
      });
    }
  }

  //savind Data
  Future<void> saveFavoriteAudioPaths() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance(); //get instance in key value pair
    prefs.setStringList('favoritePaths',
        favoriteAudioPaths); //setString is Sp method for storing list of strings
  }

  /////////////////////////////functions for Audioplayback
  //  Previous song method
  void seekaudio(double value) {
    final info = audioPlayer.realtimePlayingInfos
        .value; //realTime info,value=>realTime value,status of audio
    final duration = info.duration; //get duration of currenty playing song
    if (duration != null) {
      //states there is valid duration
      final newPosition = (value * duration.inMilliseconds)
          .round(); //calculates new possition based on,value,duration
      audioPlayer.seek(Duration(
          milliseconds:
              newPosition)); //moves playBack position to new possition
    }
  }

  void playPreviousSong() {
    audioPlayer.previous(); //assestsAudioPlayer method
  }

  ////
  void playNextSong() {
    audioPlayer.next();
  }

  //responsible song
  Future<void> playSong() async {
    final prefs = await SharedPreferences.getInstance();
    //get stored position of song in miliseconds,if it is null,the returns zero
    final storedPositionMiliseconds = prefs.getInt('storedPosition') ?? 0;
    //converts stored position from miliseconds to duration and assign it to storeposition
    storedPosition = Duration(milliseconds: storedPositionMiliseconds);
    if (storedPosition != null) {
      audioPlayer.seek(storedPosition!); //seeks audioPlayer to that position
      audioPlayer.play(); // plays audio from start
    } else {
      audioPlayer.play();
    }
  }

  //this code pauses the audio, captures the current playback position, and stores it in shared preferences for later use (e.g., to resume playback from the same position).
  Future<void> pausesong() async {
    audioPlayer.pause();
    //get current position of Audio Playback and assign it to store position
    storedPosition = audioPlayer.currentPosition.value;
    final prefs = await SharedPreferences.getInstance();
    //store current playback position in shared Preferences
    await prefs.setInt('storedPosition', storedPosition?.inMilliseconds ?? 0);
  }

  @override
  void dispose() {
    audioPlayer.stop(); //stops any audio before being disposed
    audioPlayer.dispose(); //dispose that it does not leak memory
    super.dispose();
  }

  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    super.initState();
    isPlaying = List.filled(firstlist.length, false); //creates a new list
    isFavorite = List.generate(firstlist.length, (index) => false);
    isBottomSheetPlaying = List.filled(firstlist.length, false);
    loadFavoriteAudioPaths(); //initialzation of load method in initState
    // this line of code adds the current object (likely a State object) as an observer to the widget binding, allowing it to receive notifications about changes in the application's lifecycle.
    WidgetsBinding.instance?.addObserver(this);
    storedPosition = Duration.zero;
    //initialization of new variable,later to be used for storing position
    audioPlayer.realtimePlayingInfos.listen((info) {
      if (info != null) {
        final duration = info.duration;
        //get current position of song
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

  //////////   playback
  void showAudioPlayerBottomSheet(int index) {
    showModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) => StatefulBuilder(builder: (BuildContext context,
                void Function(void Function()) setState) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Gap(120),
                        Text(
                          firstlist[index].text,
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        Gap(80),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                isPlaying[index] = false;
                              });
                              stopAudio();

                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.close)),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    //seekbar
                    StreamBuilder<RealtimePlayingInfos>(
                      //gives real time info
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
                              playbackPosition =
                                  playbackPosition.clamp(0.0, 1.0);
                            }
                            return Slider(
                              activeColor: Colors.black87,
                              value: playbackPosition,
                              onChanged: (double value) {
                                final realDuration =
                                    audioPlayer.current.value!.audio.duration;
                                int newPosition =
                                    (value * realDuration.inMilliseconds)
                                        .round();
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
                            activeColor: Colors.black87);
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
                            for (int i = 0;
                                i < isBottomSheetPlaying.length;
                                i++) {
                              // If the current index is not equal to the target index and isBottomSheetPlaying[i] is true
                              if (i != index && isBottomSheetPlaying[i]) {
                                // Stop the audio for the previous button
                                stopAudio();
                                // Set isBottomSheetPlaying[i] to false (turn off the previous button)
                                isBottomSheetPlaying[i] = false;
                              }
                            }
                            // If the current button is playing, pause the song; otherwise, play the audio for the current index
                            if (isBottomSheetPlaying[index]) {
                              pausesong();
                            } else {
                              playAudio(index);
                            }
                            // Toggle the state of isBottomSheetPlaying for the current index
                            isBottomSheetPlaying[index] =
                                !isBottomSheetPlaying[index];
                            setState(() {});
                          },
                          icon: Icon(
                            isBottomSheetPlaying[index]
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              pausesong();
                            },
                            icon: Icon(Icons.skip_next)),
                        SizedBox(
                          width: 50.w,
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PlayerScreen(index: index)));
                            },
                            icon: Icon(Icons.fit_screen_sharp)),
                      ],
                    ),
                  ],
                ),
              );
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Text(
          'ISLAMIC RINGTONES',
          style: TextStyle(
              color: Colors.white, fontSize: 15.sp, fontFamily: 'sans_regular'),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.star_half)),
        ],
        bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(color: Colors.white),
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            dividerColor: Colors.green,
            tabs: const [
              Tab(
                text: 'Ringtones',
              ),
              Tab(
                text: 'Favorites',
              ),
              Tab(
                text: 'Recommend',
              ),
            ]),
      ),
      drawer: Drawer(
          backgroundColor: Colors.green,
          child: ListView(
            children: [
              DrawerHeader(
                curve: Curves.linear,
                child: Text(
                  'Drawer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontFamily: 'sans_regular'),
                ),
              ),
              InkWell(
                onTap: null,
                child: ListTile(
                  title: const Text(
                    'Quranic Verses',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
              ),
              ListTile(
                title: const Text(
                  'Hadith',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                title: const Text(
                  'Dua',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                title: const Text(
                  'Prayer Timings',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                title: const Text(
                  'Qibla Direction',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
            ],
          )),
      body: Column(
        children: [
          SizedBox(
            height: 20.h,
          ),
          Text(
            'ISLAMIC',
            style: TextStyle(color: Colors.yellowAccent, fontSize: 25.sp),
          ),
          Text(
            'RINGTONES',
            style: TextStyle(color: Colors.yellowAccent, fontSize: 25.sp),
          ),
          SizedBox(
            height: 20.h,
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              ListView.builder(
                itemCount: firstlist.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 60.h,
                    width: 30.w,
                    child: InkWell(
                      child: Card(
                        surfaceTintColor: Colors.black,
                        shadowColor: Colors.grey,
                        margin: const EdgeInsets.all(8.0),
                        color: Colors.green,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notification_add,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Text(
                              firstlist[index].text,
                              style: TextStyle(
                                  fontSize: 15.sp, color: Colors.white),
                            ),
                            SizedBox(
                              width: 50.w,
                            ),
                            IconButton(
                              onPressed: () {
                                for (int i = 0; i < isPlaying.length; i++) {
                                  // If the current index is not equal to the target index and isPlaying[i] is true
                                  if (i != index && isPlaying[i]) {
                                    stopAudio(); // Stop the audio for the previous button
                                    isPlaying[i] =
                                        false; // here, the previous button goes off upon the functioning of new button
                                  }
                                }
                                // If the current button is playing, stop the audio and turn off the current button
                                if (isPlaying[index]) {
                                  stopAudio();
                                  isPlaying[index] = false;
                                } else {
                                  playAudio(
                                      index); // Plays the audio for the current index

                                  isPlaying[index] =
                                      true; // Turn on the current button
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                isPlaying[index]
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isFavorite[index] = !isFavorite[index];
                                  if (isFavorite[index]) {
                                    // marked as favorite
                                    favoriteAudioPaths
                                        .add(firstlist[index].audioPaths);
                                  } else {
                                    // to unTap, Uncheck button,removes from fav

                                    favoriteAudioPaths
                                        .remove(firstlist[index].audioPaths);
                                  }
                                  saveFavoriteAudioPaths();
                                  // print(favoriteAudioPaths.length);
                                  log(favoriteAudioPaths.length);
                                });
                              },
                              icon: Icon(Icons.favorite,
                                  color: isFavorite[index]
                                      ? Colors.amber
                                      : Colors.white),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.volume_up_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        onBellIconPressed(index);
                      },
                    ),
                  );
                },
              ),
              ListView.builder(
                itemCount: favoriteAudioPaths.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.teal)),
                    textColor: Colors.white,
                    tileColor: Colors.grey,
                    title: Text(
                      'Favorite ${index + 1}',
                    ),
                    leading: IconButton(
                      onPressed: () {
                        for (int i = 0; i < isPlaying.length; i++) {
                          // If the current index is not equal to the target index and isPlaying[i] is true
                          if (i != index && isPlaying[i]) {
                            stopAudio(); // it is stoping audio for previous button
                            isPlaying[i] =
                                false; // here, the previous button goes off on the functioning of new button
                          }
                        }
                        // If the current button is playing, stop the audio and turn on the current button
                        if (isPlaying[index]) {
                          stopAudio();
                          isPlaying[index] = true;
                        } else {
                          playAudio(
                              index); // Play the audio for the current index
                          isPlaying[index] = true; // Turn on the current button
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        isPlaying[index] ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      playAudioFromPath();
                    },
                  ),
                ),
              ),
              Container(
                color: Colors.red,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
