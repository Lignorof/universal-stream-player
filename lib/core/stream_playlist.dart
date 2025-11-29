class StreamPlaylist {
  final String id;
  final String name;
  final String imageUrl;
  final String owner;
  final String source;

  StreamPlaylist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.owner,
    required this.source,
  });

  factory StreamPlaylist.fromSpotifyJson(Map<String, dynamic> json) {
    return StreamPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Playlist Sem Nome',
      imageUrl: (json['images'] as List).isNotEmpty ? json['images'][0]['url'] : '',
      owner: json['owner']?['display_name'] ?? 'Desconhecido',
      source: 'spotify',
    );
  }

  // Construtor para dados vindos da API do Deezer
  factory StreamPlaylist.fromDeezerJson(Map<String, dynamic> json) {
    return StreamPlaylist(
      // O ID do Deezer é um int, convertemos para String para consistência
      id: json['id']?.toString() ?? '',
      name: json['title'] ?? 'Playlist Sem Nome',
      // Deezer tem diferentes tamanhos de imagem, pegamos a média
      imageUrl: json['picture_medium'] ?? '',
      owner: json['user']?['name'] ?? 'Desconhecido',
      source: 'deezer',
    );
  }

  factory StreamPlaylist.fromDbJson(Map<String, dynamic> json) {
    return StreamPlaylist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      owner: json['owner'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toDbJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'owner': owner,
        'source': source,
      };
}

