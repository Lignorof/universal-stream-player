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
        id: m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        source: m['source'] as String?,
        tracks: (m['tracks'] as List<dynamic>?)
                ?.map((e) => e is Map ? StreamTrack.fromMap(Map<String, dynamic>.from(e)) : StreamTrack.fromMap({}))
                .toList() ??
            [],
      );

  /// Parse a Spotify playlist object or equivalent shape.
  /// Accepts either:
  /// - playlist['tracks'] as a List<Map> OR
  /// - playlist['tracks'] as object with 'items' where each item has 'track'
  factory StreamPlaylist.fromSpotifyJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['name'] as String? ?? json['title'] as String? ?? '';
    List<StreamTrack> tracks = [];

    final tracksNode = json['tracks'];
    if (tracksNode is List) {
      tracks = tracksNode.map((t) {
        if (t is Map) return StreamTrack.fromSpotifyJson(Map<String, dynamic>.from(t));
        return StreamTrack.fromMap({});
      }).toList();
    } else if (tracksNode is Map && tracksNode['items'] is List) {
      final items = tracksNode['items'] as List;
      tracks = items.map((item) {
        if (item is Map) {
          // Spotify playlist items often have a 'track' key
          final trackObj = item['track'] is Map ? item['track'] as Map<String, dynamic> : item as Map<String, dynamic>;
          return StreamTrack.fromSpotifyJson(Map<String, dynamic>.from(trackObj));
        }
        return StreamTrack.fromMap({});
      }).toList();
    }

    // Fallback to an explicit 'items' or 'tracks' top-level list
    if (tracks.isEmpty) {
      final fallback = json['items'] as List?;
      if (fallback != null) {
        tracks = fallback.map((e) {
          if (e is Map) {
            final trackObj = e['track'] is Map ? e['track'] as Map<String, dynamic> : e as Map<String, dynamic>;
            return StreamTrack.fromSpotifyJson(Map<String, dynamic>.from(trackObj));
          }
          return StreamTrack.fromMap({});
        }).toList();
      }
    }

    return StreamPlaylist(id: id, title: title, tracks: tracks, source: 'spotify');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'source': source,
        'tracks': tracks.map((t) => t.toMap()).toList(),
      };

  factory StreamPlaylist.fromJson(Map<String, dynamic> json) => StreamPlaylist.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
