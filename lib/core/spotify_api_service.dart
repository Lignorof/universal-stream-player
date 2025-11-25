import 'dart:convert';
import 'package:http/http.dart' as http;
// Importe AMBOS os seus modelos
import '../model/stream_playlist.dart'; 
import '../model/stream_track.dart';

class SpotifyApiService {
  final String _accessToken;
  static const String _baseUrl = 'https://api.spotify.com/v1';

  SpotifyApiService(this._accessToken );

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  // Função genérica para buscar dados paginados (sem alterações)
  Future<List<T>> _fetchPagedData<T>(String endpoint, T Function(Map<String, dynamic>) fromJson) async {
    List<T> allItems = [];
    String? nextUrl = '$_baseUrl/$endpoint';

    while (nextUrl != null) {
      final response = await http.get(Uri.parse(nextUrl ), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // O endpoint 'me/tracks' tem um formato um pouco diferente,
        // o item real está dentro de um objeto 'track'.
        // O seu modelo já lida com isso, então o código aqui permanece genérico.
        final items = (data['items'] as List).map((item) => fromJson(item)).toList();
        allItems.addAll(items);
        nextUrl = data['next'];
      } else {
        throw Exception('Falha ao carregar dados de $endpoint: ${response.body}');
      }
    }
    return allItems;
  }

  // --- MÉTODOS DA API ---

  Future<List<StreamPlaylist>> getCurrentUserPlaylists() async {
    return _fetchPagedData('me/playlists?limit=50', (json) => StreamPlaylist.fromSpotifyJson(json));
  }

  // --- NOVO MÉTODO ADICIONADO ---
  Future<List<StreamTrack>> getSavedTracks() async {
    // Usa o construtor de fábrica do seu modelo StreamTrack.
    return _fetchPagedData('me/tracks?limit=50', (json) => StreamTrack.fromSpotifyJson(json));
  }

  // Adicione os outros métodos aqui (Artistas, Álbuns) quando precisar.
}

