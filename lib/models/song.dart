import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? albumArt;
  final String filePath;
  final String? url;
  final Duration duration;
  final String? genre;
  final DateTime addedDate;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumArt,
    required this.filePath,
    this.url,
    required this.duration,
    this.genre,
    required this.addedDate,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        albumArt,
        filePath,
        url,
        duration,
        genre,
        addedDate,
      ];

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArt,
    String? filePath,
    String? url,
    Duration? duration,
    String? genre,
    DateTime? addedDate,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArt: albumArt ?? this.albumArt,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArt': albumArt,
      'filePath': filePath,
      'url': url,
      'duration': duration.inSeconds,
      'genre': genre,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      albumArt: json['albumArt'] as String?,
      filePath: json['filePath'] as String,
      url: json['url'] as String?,
      duration: Duration(seconds: json['duration'] as int),
      genre: json['genre'] as String?,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
