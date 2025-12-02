import 'stream_track.dart';

class StreamPlaylist {
  final String id;
  final String title;
  final List<StreamTrack> tracks;
  final String? source;

  StreamPlaylist({
    required this.id,
    required this.title,
    this.tracks = const [],
    this.source,
  });

  factory StreamPlaylist.fromMap(Map<String, dynamic> m) => StreamPlaylist(
        id: m['id'] as String,
        title: m['title'] as String,
        source: m['source'] as String?,
        tracks: (m['tracks'] as List<dynamic>?)
                ?.map((e) => StreamTrack.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'source': source,
        'tracks': tracks.map((t) => t.toMap()).toList(),
      };

  factory StreamPlaylist.fromJson(Map<String, dynamic> json) => StreamPlaylist.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}