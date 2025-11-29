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
  static final String _spotifyClientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static final String _deezerAppId = dotenv.env['DEEZER_APP_ID'] ?? '';
  static bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS );
  static String get _spotifyRedirectUri => _isDesktop ? 'http://127.0.0.1:8000/callback' : 'usp://callback';
  static String get _spotifyCallbackScheme => _isDesktop ? 'http://127.0.0.1:8000' : 'usp';
  static String get _deezerRedirectUri => _isDesktop ? 'http://127.0.0.1:8001/callback' : 'usp://deezer-callback';
  static String get _deezerCallbackScheme => _isDesktop ? 'http://127.0.0.1:8001' : 'usp';
  static const String _spotifyTokenKey = 'usp_spotify_access_token';
  static const String _spotifyRefreshTokenKey = 'usp_spotify_refresh_token';
  static const String _deezerTokenKey = 'usp_deezer_access_token';

  String? _spotifyAccessToken;
  String? _deezerAccessToken;
  String? get spotifyAccessToken => _spotifyAccessToken;
  String? get deezerAccessToken => _deezerAccessToken;
  bool get isSpotifyAuthenticated => _spotifyAccessToken != null;
  bool get isDeezerAuthenticated => _deezerAccessToken != null;
  bool get isAuthenticated => isSpotifyAuthenticated || isDeezerAuthenticated;

  AuthService( ) {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _spotifyAccessToken = prefs.getString(_spotifyTokenKey);
    _deezerAccessToken = prefs.getString(_deezerTokenKey);
    notifyListeners();
  }

  Future<void> loginSpotify() async {
    if (_spotifyClientId.isEmpty) throw Exception('SPOTIFY_CLIENT_ID não encontrado');
    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    
    final scopes = [
      'user-read-private',
      'user-library-read',
      'playlist-read-private',
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
      final result = await FlutterWebAuth2.authenticate(url: authUrl.toString(), callbackUrlScheme: _spotifyCallbackScheme);
      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeSpotifyCode(code, codeVerifier);
      } else {
        throw Exception('Código de autorização não retornado.');
      }
    } catch (e) {
      if (e.toString().contains('CANCELED')) return;
      throw Exception('Falha no login com Spotify: $e');
    }
  }

  // ADICIONADO DE VOLTA
  Future<void> loginDeezer() async {
    if (_deezerAppId.isEmpty) throw Exception('DEEZER_APP_ID não encontrado');
    final authUrl = Uri.https('connect.deezer.com', '/oauth/auth.php', {
      'app_id': _deezerAppId,
      'redirect_uri': _deezerRedirectUri,
      'perms': 'basic_access,manage_library',
      'response_type': 'token',
    } );
    try {
      final result = await FlutterWebAuth2.authenticate(url: authUrl.toString(), callbackUrlScheme: _deezerCallbackScheme);
      final fragment = Uri.parse(result).fragment;
      final token = Uri.splitQueryString(fragment)['access_token'];
      if (token != null) {
        _deezerAccessToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_deezerTokenKey, _deezerAccessToken!);
        notifyListeners();
      } else {
        throw Exception('Token do Deezer não encontrado.');
      }
    } catch (e) {
      if (e.toString().contains('CANCELED')) return;
      throw Exception('Falha no login com Deezer: $e');
    }
  }

  Future<void> _exchangeSpotifyCode(String code, String codeVerifier) async {
    final url = Uri.parse('https://accounts.spotify.com/api/token' );
    final response = await http.post(url, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _spotifyRedirectUri,
      'client_id': _spotifyClientId,
      'code_verifier': codeVerifier,
    } );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _spotifyAccessToken = body['access_token'];
      final refreshToken = body['refresh_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spotifyTokenKey, _spotifyAccessToken!);
      if (refreshToken != null) {
        await prefs.setString(_spotifyRefreshTokenKey, refreshToken);
      }
      notifyListeners();
    } else {
      throw Exception('Falha ao trocar o código do Spotify: ${response.body}');
    }
  }

  Future<String?> refreshSpotifyToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_spotifyRefreshTokenKey);
    if (refreshToken == null) {
      await logout();
      return null;
    }
    final url = Uri.parse('https://accounts.spotify.com/api/token' );
    final response = await http.post(url, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': _spotifyClientId,
    } );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _spotifyAccessToken = body['access_token'];
      final newRefreshToken = body['refresh_token'];
      await prefs.setString(_spotifyTokenKey, _spotifyAccessToken!);
      if (newRefreshToken != null) {
        await prefs.setString(_spotifyRefreshTokenKey, newRefreshToken);
      }
      notifyListeners();
      return _spotifyAccessToken;
    } else {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    _spotifyAccessToken = null;
    _deezerAccessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_spotifyTokenKey);
    await prefs.remove(_spotifyRefreshTokenKey);
    await prefs.remove(_deezerTokenKey);
    notifyListeners();
  }

  String _generateRandomString(int length) {
    final r = Random.secure();
    const c = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~';
    return List.generate(length, (_) => c[r.nextInt(c.length)]).join();
  }

  String _generateCodeChallenge(String v) {
    final b = utf8.encode(v);
    final d = sha256.convert(b);
    return base64Url.encode(d.bytes).replaceAll('=', '');
  }
}

