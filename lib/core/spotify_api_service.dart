
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'stream_playlist.dart';
import 'stream_track.dart';

class SpotifyApiService {
  final String _accessToken;
  final AuthService _authService;
  static const String _baseUrl = 'https://api.spotify.com/v1';

  SpotifyApiService(this._accessToken, this._authService );

  Future<T> _handleRequest<T>(Future<http.Response> Function( ) request, T Function(dynamic) onSuccess) async {
    var response = await request();
    if (response.statusCode == 401) {
      final newAccessToken = await _authService.refreshSpotifyToken();
      if (newAccessToken != null) {
        response = await request(); // Tenta novamente com o novo token
      } else {
        throw Exception('Sessão expirada. Por favor, faça login novamente.');
      }
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return onSuccess(data);
    } else {
      throw Exception('Falha ao carregar dados: ${response.body}');
    }
  }

  Future<List<R>> _fetchPagedData<R>(String endpoint, R Function(Map<String, dynamic>) fromJson) async {
    return _handleRequest(() async {
      return http.get(
        Uri.parse('$_baseUrl/$endpoint' ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
    }, (data) {
      final itemsList = (data['items'] as List?) ?? [];
      // --- CORREÇÃO DEFINITIVA PARA O ERRO DE TYPE CAST ---
      // Filtra itens onde o campo 'track' é nulo ANTES de tentar o parse.
      return itemsList
          .where((item) => item['track'] != null)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<StreamPlaylist>> getCurrentUserPlaylists() async {
    return _handleRequest(() async {
      return http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=50' ),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
    }, (data) {
      final itemsList = (data['items'] as List?) ?? [];
      return itemsList.map((item) => StreamPlaylist.fromSpotifyJson(item)).toList();
    });
  }

  Future<List<StreamTrack>> getSavedTracks() async {
    return _fetchPagedData('me/tracks?limit=50', (json) => StreamTrack.fromSpotifyJson(json));
  }

  Future<List<StreamTrack>> getPlaylistTracks(String playlistId) async {
    final cleanPlaylistId = Uri.encodeComponent(playlistId);
    return _fetchPagedData('playlists/$cleanPlaylistId/tracks?limit=100', (json) => StreamTrack.fromSpotifyJson(json));
  }
}

