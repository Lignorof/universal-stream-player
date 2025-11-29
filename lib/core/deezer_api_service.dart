import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stream_playlist.dart';

class DeezerApiService {
  final String _accessToken;
  static const String _baseUrl = 'https://api.deezer.com';
  DeezerApiService(this._accessToken );

  Future<List<StreamPlaylist>> getCurrentUserPlaylists() async {
    final response = await http.get(Uri.parse('$_baseUrl/user/me/playlists?access_token=$_accessToken' ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final itemsList = (data['data'] as List?) ?? [];
      return itemsList.map((json) => StreamPlaylist.fromDeezerJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar playlists do Deezer: ${response.body}');
    }
  }
}
