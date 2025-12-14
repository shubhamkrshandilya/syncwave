import 'package:equatable/equatable.dart';
import 'song.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final List<Song> songs;
  final DateTime createdDate;
  final DateTime modifiedDate;
  final bool isShared;
  final String? shareCode;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.songs,
    required this.createdDate,
    required this.modifiedDate,
    this.isShared = false,
    this.shareCode,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        coverImage,
        songs,
        createdDate,
        modifiedDate,
        isShared,
        shareCode,
      ];

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    List<Song>? songs,
    DateTime? createdDate,
    DateTime? modifiedDate,
    bool? isShared,
    String? shareCode,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      songs: songs ?? this.songs,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isShared: isShared ?? this.isShared,
      shareCode: shareCode ?? this.shareCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'modifiedDate': modifiedDate.toIso8601String(),
      'isShared': isShared,
      'shareCode': shareCode,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      songs: (json['songs'] as List<dynamic>)
          .map((songJson) => Song.fromJson(songJson as Map<String, dynamic>))
          .toList(),
      createdDate: DateTime.parse(json['createdDate'] as String),
      modifiedDate: DateTime.parse(json['modifiedDate'] as String),
      isShared: json['isShared'] as bool? ?? false,
      shareCode: json['shareCode'] as String?,
    );
  }

  int get songCount => songs.length;

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (total, song) => total + song.duration,
    );
  }

  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }
}
