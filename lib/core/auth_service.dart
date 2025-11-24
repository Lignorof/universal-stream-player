import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // ... (credenciais e getters continuam iguais ) ...
  static final String _spotifyClientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? 'SPOTIFY_ID_NAO_ENCONTRADO';
  static const String _spotifyTokenKey = 'usp_spotify_access_token';
  static const String _spotifyRefreshTokenKey = 'usp_spotify_refresh_token';
  String? _spotifyAccessToken;
  static final String _deezerAppId = dotenv.env['DEEZER_APP_ID'] ?? 'DEEZER_ID_NAO_ENCONTRADO';
  static const String _deezerTokenKey = 'usp_deezer_access_token';
  String? _deezerAccessToken;
  String? get spotifyAccessToken => _spotifyAccessToken;
  String? get deezerAccessToken => _deezerAccessToken;
  bool get isSpotifyAuthenticated => _spotifyAccessToken != null;
  bool get isDeezerAuthenticated => _deezerAccessToken != null;
  bool get isAuthenticated => isSpotifyAuthenticated || isDeezerAuthenticated;

  Future<void> loadAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _spotifyAccessToken = prefs.getString(_spotifyTokenKey);
    _deezerAccessToken = prefs.getString(_deezerTokenKey);
  }

  Future<void> loginSpotify() async {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final spotifyRedirectUri = isMobile ? 'usp://callback' : 'http://localhost:8080';
    final callbackUrlScheme = isMobile ? 'usp' : 'http://localhost:8080'; // Usando 'http://localhost:8080' para desktop

    final codeVerifier = _generateRandomString(128 );
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final scopes = ['user-read-private', 'playlist-read-private', 'user-library-read'].join(' ');
    
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'response_type': 'code',
      'client_id': _spotifyClientId,
      'redirect_uri': spotifyRedirectUri,
      'scope': scopes,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
    } );

    // Chamada SEM preferEphemeral
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(), 
      callbackUrlScheme: callbackUrlScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code != null) {
      await _exchangeCodeForToken(code, codeVerifier, spotifyRedirectUri);
    } else {
      throw Exception('Código de autorização do Spotify não encontrado.');
    }
  }

  Future<void> _exchangeCodeForToken(String code, String codeVerifier, String redirectUri) async {
    // ... (esta função não muda) ...
    final url = Uri.parse('https://accounts.spotify.com/api/token' );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': _spotifyClientId,
        'code_verifier': codeVerifier,
      },
     );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _spotifyAccessToken = body['access_token'];
      final refreshToken = body['refresh_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spotifyTokenKey, _spotifyAccessToken!);
      if (refreshToken != null) {
        await prefs.setString(_spotifyRefreshTokenKey, refreshToken);
      }
    } else {
      throw Exception('Falha ao trocar o código pelo token: ${response.body}');
    }
  }

  Future<void> loginDeezer() async {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final deezerRedirectUri = isMobile ? 'usp://deezer-callback' : 'http://localhost:8081';
    final callbackUrlScheme = isMobile ? 'usp' : 'http://localhost:8081';

    final authUrl = Uri.https('connect.deezer.com', '/oauth/auth.php', {
      'app_id': _deezerAppId,
      'redirect_uri': deezerRedirectUri,
      'perms': 'basic_access,manage_library',
      'response_type': 'token',
    } );

    // Chamada SEM preferEphemeral
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(), 
      callbackUrlScheme: callbackUrlScheme,
    );

    final token = Uri.splitQueryString(Uri.parse(result).fragment)['access_token'];

    if (token != null) {
      _deezerAccessToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deezerTokenKey, _deezerAccessToken!);
    } else {
      throw Exception('Token do Deezer não encontrado.');
    }
  }

  // ... (funções de suporte ao PKCE não mudam) ...
  String _generateRandomString(int length) {
    final random = Random.secure();
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~';
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

