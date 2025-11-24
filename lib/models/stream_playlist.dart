class StreamPlaylist {
  final String id;
  final String name;
  final String imageUrl;
  final String owner;
  final String source; // 'spotify' ou 'deezer'

  StreamPlaylist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.owner,
    required this.source,
  });

  // Construtor para dados vindos da API do Spotify
  factory StreamPlaylist.fromSpotifyJson(Map<String, dynamic> json) {
    return StreamPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Playlist Sem Nome',
      imageUrl: (json['images'] as List).isNotEmpty ? json['images'][0]['url'] : '',
      owner: json['owner']?['display_name'] ?? 'Desconhecido',
      source: 'spotify',
    );
  }

  // Construtor para dados vindos do nosso banco de dados
  factory StreamPlaylist.fromDbJson(Map<String, dynamic> json) {
    return StreamPlaylist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      owner: json['owner'],
      source: json['source'],
    );
  }

  // Método para converter o objeto para um formato JSON para o DB
  Map<String, dynamic> toDbJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'owner': owner,
        'source': source,
      };
}
