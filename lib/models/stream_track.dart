class StreamTrack {
  final String name;
  final String artist;
  final String albumName;
  final String imageUrl;

  StreamTrack({
    required this.name,
    required this.artist,
    required this.albumName,
    required this.imageUrl,
  });

  // Construtor para dados vindos da API do Spotify
  factory StreamTrack.fromSpotifyJson(Map<String, dynamic> json) {
    final track = json['track'] ?? {};
    if (track.isEmpty) return StreamTrack(name: 'Faixa indisponível', artist: '', albumName: '', imageUrl: '');

    final artistName = (track['artists'] as List).map((artist) => artist['name']).join(', ');
    final album = track['album'] ?? {};
    final images = album['images'] as List? ?? [];

    return StreamTrack(
      name: track['name'] ?? 'Faixa Sem Nome',
      artist: artistName,
      albumName: album['name'] ?? 'Álbum Desconhecido',
      imageUrl: images.isNotEmpty ? images[0]['url'] : '',
    );
  }

  // Construtor para dados vindos da API do Deezer
  factory StreamTrack.fromDeezerJson(Map<String, dynamic> json) {
    return StreamTrack(
      name: json['title'] ?? '',
      artist: json['artist']?['name'] ?? '',
      albumName: json['album']?['title'] ?? '',
      imageUrl: json['album']?['cover_medium'] ?? '',
    );
  }

  // Construtor para dados vindos do nosso banco de dados
  factory StreamTrack.fromDbJson(Map<String, dynamic> json) {
    return StreamTrack(
      name: json['name'],
      artist: json['artist'],
      albumName: json['albumName'],
      imageUrl: json['imageUrl'],
    );
  }

  // Método para converter o objeto para um formato JSON para o DB
  Map<String, dynamic> toDbJson(String playlistId) => {
        'playlistId': playlistId,
        'name': name,
        'artist': artist,
        'albumName': albumName,
        'imageUrl': imageUrl,
      };
}
