import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stream_playlist.dart';

class DeezerApiService {
  final String _accessToken;
  static const String _baseUrl = 'https://api.deezer.com';

  DeezerApiService(this._accessToken );

  Future<List<StreamPlaylist>> getCurrentUserPlaylists() async {
    // A API do Deezer requer o token como um parâmetro de query
    final url = Uri.parse('$_baseUrl/user/me/playlists?access_token=$_accessToken');

    final response = await http.get(url );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // A resposta do Deezer para playlists está na chave 'data'
      final itemsList = (data['data'] as List?);
      if (itemsList == null) {
        return <StreamPlaylist>[];
      }
      return itemsList
          .map((item) => StreamPlaylist.fromDeezerJson(item))
          .toList();
    } else {
      // A API do Deezer pode retornar erros de token aqui.
      // Uma implementação mais robusta lidaria com a expiração do token.
      throw Exception('Falha ao carregar playlists do Deezer: ${response.body}');
    }
  }
}

