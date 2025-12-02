class StreamTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? durationMs;
  final String? url;
  final String? source;

  StreamTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.url,
    this.source,
  });

  factory StreamTrack.fromMap(Map<String, dynamic> m) => StreamTrack(
        id: m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        artist: m['artist'] as String? ?? '',
        album: m['album'] as String?,
        durationMs: m['durationMs'] as int?,
        url: m['url'] as String?,
        source: m['source'] as String?,
      );

  /// Parse a Deezer track JSON object (common fields).
  factory StreamTrack.fromDeezerJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['title'] as String? ?? (json['name'] as String?) ?? '';
    final artistName = (json['artist'] is Map) ? (json['artist']['name'] as String?) : null;
    final artist = artistName ?? (json['artist'] as String?) ?? '';
    final albumTitle = (json['album'] is Map) ? (json['album']['title'] as String?) : null;
    final durationSec = json['duration'];
    final durationMs = (durationSec is int) ? durationSec * 1000 : null;
    final url = json['preview'] as String? ?? (json['link'] as String?);
    return StreamTrack(
      id: id,
      title: title,
      artist: artist,
      album: albumTitle,
      durationMs: durationMs,
      url: url,
      source: 'deezer',
    );
  }

  /// Parse a Spotify track JSON object (common fields).
  factory StreamTrack.fromSpotifyJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['name'] as String? ?? '';
    String artist = '';
    if (json['artists'] is List) {
      try {
        final list = json['artists'] as List;
        artist = list.map((a) => (a is Map ? (a['name'] as String?) : (a as String?))).whereType<String>().join(', ');
      } catch (_) {
        artist = '';
      }
    } else if (json['artist'] is Map) {
      artist = json['artist']['name'] as String? ?? '';
    } else {
      artist = json['artist'] as String? ?? '';
    }
    final albumTitle = (json['album'] is Map) ? (json['album']['name'] as String?) : null;
    final durationMs = json['duration_ms'] is int ? json['duration_ms'] as int : null;
    String? url;
    if (json['external_urls'] is Map) {
      url = (json['external_urls']['spotify'] as String?) ?? url;
    }
    // Some manifests provide preview_url
    url = url ?? (json['preview_url'] as String?);
    return StreamTrack(
      id: id,
      title: title,
      artist: artist,
      album: albumTitle,
      durationMs: durationMs,
      url: url,
      source: 'spotify',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'durationMs': durationMs,
        'url': url,
        'source': source,
      };

  factory StreamTrack.fromJson(Map<String, dynamic> json) => StreamTrack.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
