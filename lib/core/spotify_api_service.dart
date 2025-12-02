import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_token_provider.dart';
import 'stream_playlist.dart';
import 'stream_track.dart';

class SpotifyApiService {
  final AuthTokenProvider _tokenProvider;
  static const String _baseUrl = 'https://api.spotify.com/v1';

  SpotifyApiService(this._tokenProvider);

  Future<T> _handleApiCall<T>(Future<http.Response> Function(String token) apiCall, T Function(dynamic) onSuccess) async {
    final accessToken = await _tokenProvider.getAccessToken();
    if (accessToken == null) {
      throw Exception('Não foi possível obter o token de acesso. Faça login novamente.');
    }
    var response = await apiCall(accessToken);
    if (response.statusCode == 401) {
      final newAccessToken = await _tokenProvider.refreshToken();
      if (newAccessToken != null) {
        response = await apiCall(newAccessToken); // Tenta novamente com o novo token
      } else {
        throw Exception('Não foi possível renovar a sessão. Faça login novamente.');
      }
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return onSuccess(data);
    } else {
      throw Exception('Falha ao carregar dados: ${response.body}');
    }
  }

  Future<List<T>> _fetchPagedData<T>(String endpoint, T Function(Map<String, dynamic>) fromJson) async {
    return _handleApiCall(
      (token) => http.get(Uri.parse('$_baseUrl/$endpoint'), headers: {'Authorization': 'Bearer $token'}),
      (data) {
        final items = data['items'] as List?;
        if (items == null) return <T>[];
        return items.map((itemJson) => fromJson(itemJson as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<List<StreamPlaylist>> getCurrentUserPlaylists() async {
    return _fetchPagedData('me/playlists?limit=50', (json) => StreamPlaylist.fromSpotifyJson(json));
  }

  Future<List<StreamTrack>> getSavedTracks() async {
    return _fetchPagedData('me/tracks?limit=50', (json) => StreamTrack.fromSpotifyJson(json));
  }

  Future<List<StreamTrack>> getPlaylistTracks(String playlistId) async {
    final cleanPlaylistId = playlistId.split(':').last;
    return _fetchPagedData('playlists/$cleanPlaylistId/tracks?limit=100', (json) => StreamTrack.fromSpotifyJson(json));
  }
}

