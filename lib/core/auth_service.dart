import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  // --- Configuração de Credenciais e URIs ---
  static final String _spotifyClientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS );

  static String get _spotifyRedirectUri =>
      _isDesktop ? 'http://127.0.0.1:8000/callback' : 'usp://callback';

  static String get _spotifyCallbackScheme => _isDesktop ? 'http' : 'usp';

  static const String _spotifyTokenKey = 'usp_spotify_access_token';
  static const String _spotifyRefreshTokenKey = 'usp_spotify_refresh_token';

  // --- Estado de Autenticação ---
  String? _accessToken;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  // --- Inicialização ---
  AuthService( ) {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_spotifyTokenKey);
    if (token != null) {
      _accessToken = token;
      notifyListeners();
    }
  }

  // --- Métodos Públicos ---
  Future<void> loginSpotify() async {
    if (_spotifyClientId.isEmpty) {
      throw Exception('SPOTIFY_CLIENT_ID não encontrado no arquivo .env');
    }

    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final scopes = [
      'user-read-private',
      'playlist-read-private',
      'user-library-read'
    ].join(' ');

    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'response_type': 'code',
      'client_id': _spotifyClientId,
      'redirect_uri': _spotifyRedirectUri,
      'scope': scopes,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
    } );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: _spotifyCallbackScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        await _exchangeCodeForToken(code, codeVerifier);
      } else {
        throw Exception('Código de autorização não retornado pelo Spotify.');
      }
    } catch (e) {
      if (e.toString().contains('CANCELED')) {
        debugPrint("Login cancelado pelo usuário.");
        return;
      }
      throw Exception('Falha no login: $e');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_spotifyTokenKey);
    await prefs.remove(_spotifyRefreshTokenKey);
    notifyListeners();
  }

  // --- Métodos Privados ---
  Future<void> _exchangeCodeForToken(String code, String codeVerifier) async {
    final url = Uri.parse('https://accounts.spotify.com/api/token' );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _spotifyRedirectUri,
        'client_id': _spotifyClientId,
        'code_verifier': codeVerifier,
      },
     );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _accessToken = body['access_token'];
      final refreshToken = body['refresh_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spotifyTokenKey, _accessToken!);
      if (refreshToken != null) {
        await prefs.setString(_spotifyRefreshTokenKey, refreshToken);
      }
      notifyListeners();
    } else {
      throw Exception(
          'Falha ao trocar o código pelo token: ${response.body}');
    }
  }

  // --- Funções de Suporte ao PKCE ---
  String _generateRandomString(int length) {
    final random = Random.secure();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~';
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

