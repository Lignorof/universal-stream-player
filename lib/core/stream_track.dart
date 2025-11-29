class StreamTrack {
  final String name;
  final String artist;
  final String albumName;
  final String imageUrl;
  final bool isPlayable;

  StreamTrack({
    required this.name,
    required this.artist,
    required this.albumName,
    required this.imageUrl,
    this.isPlayable = true,
  });

  /// Construtor para dados vindos da API do Spotify.
  /// Ele é projetado para receber o objeto que está DENTRO da chave 'track'.
  factory StreamTrack.fromSpotifyJson(Map<String, dynamic>? trackData) {
    // Se o objeto track inteiro for nulo, ou não tiver um ID, é uma faixa inválida.
    if (trackData == null || trackData['id'] == null) {
      return StreamTrack(
        name: 'Faixa indisponível',
        artist: '',
        albumName: '',
        imageUrl: '',
        isPlayable: false,
      );
    }

    final artistName = (trackData['artists'] as List? ?? [])
        .map((artist) => artist['name'])
        .join(', ');
    final album = trackData['album'] ?? {};
    final images = album['images'] as List? ?? [];

    return StreamTrack(
      name: trackData['name'] ?? 'Faixa Sem Nome',
      artist: artistName,
      albumName: album['name'] ?? 'Álbum Desconhecido',
      imageUrl: images.isNotEmpty ? images[0]['url'] : '',
    );
  }

  // ... (outros construtores sem alteração)
  factory StreamTrack.fromDeezerJson(Map<String, dynamic> json) {
    return StreamTrack(
      name: json['title'] ?? '', artist: json['artist']?['name'] ?? '',
      albumName: json['album']?['title'] ?? '', imageUrl: json['album']?['cover_medium'] ?? '',
    );
  }
  factory StreamTrack.fromDbJson(Map<String, dynamic> json) {
    return StreamTrack(
      name: json['name'], artist: json['artist'],
      albumName: json['albumName'], imageUrl: json['imageUrl'],
    );
  }
  Map<String, dynamic> toDbJson(String playlistId) => {
    'playlistId': playlistId, 'name': name, 'artist': artist,
    'albumName': albumName, 'imageUrl': imageUrl,
  };
}

