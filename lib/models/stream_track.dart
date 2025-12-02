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
        id: m['id'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String,
        album: m['album'] as String?,
        durationMs: m['durationMs'] as int?,
        url: m['url'] as String?,
        source: m['source'] as String?,
      );

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
