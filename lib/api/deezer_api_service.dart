import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_stream_player/models/stream_track.dart';

class DeezerApiService {
  final String _accessToken;
  final _baseUrl = 'https://api.deezer.com';

  DeezerApiService(this._accessToken );

  Future<List<StreamTrack>> searchTracks(String query) async {
    final url = Uri.parse('$_baseUrl/search?q=$query&access_token=$_accessToken');
    final response = await http.get(url );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((item) => StreamTrack.fromDeezerJson(item)).toList();
    } else {
      throw Exception('Falha na busca do Deezer.');
    }
  }
}
