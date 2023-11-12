import 'package:flutter/material.dart';

class Data {
  String text;
  String audioPaths;
  // final List<String> favoriteAudioPaths;
  bool isFavorite;
  Data({
    required this.text,
    required this.audioPaths,
    // required this.favoriteAudioPaths,
     required this.isFavorite,
  });
}
