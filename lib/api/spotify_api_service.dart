import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_stream_player/models/stream_playlist.dart';
import 'package:universal_stream_player/models/stream_track.dart';

class SpotifyApiService {
  final String _accessToken;
  final _baseUrl = 'https://api.spotify.com/v1';

  SpotifyApiService(this._accessToken );

  Future<List<StreamPlaylist>> fetchUserPlaylists() async {
    final url = Uri.parse('$_baseUrl/me/playlists?limit=50');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $_accessToken'} );
    if (response.statusCode == 200) {
      final items = jsonDecode(response.body)['items'] as List;
      return items.map((item) => StreamPlaylist.fromSpotifyJson(item)).toList();
    } else {
      throw Exception('Falha ao buscar playlists do Spotify.');
    }
  }

  Future<List<StreamTrack>> fetchPlaylistTracks(String playlistId) async {
    final url = Uri.parse('$_baseUrl/playlists/$playlistId/tracks');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $_accessToken'} );
    if (response.statusCode == 200) {
      final items = jsonDecode(response.body)['items'] as List;
      return items.map((item) => StreamTrack.fromSpotifyJson(item)).toList();
    } else {
      throw Exception('Falha ao buscar músicas da playlist.');
    }
  }
}
