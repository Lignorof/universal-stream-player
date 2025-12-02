import 'package:flutter_test/flutter_test.dart';
import 'package:universal_stream_player/core/auth_token_provider.dart';
import 'package:universal_stream_player/core/spotify_auth_token_provider.dart';
import 'package:universal_stream_player/core/auth_service.dart';

/// A mock AuthService that allows us to control tokens for testing
/// without relying on actual SharedPreferences or network calls.
class MockAuthService extends AuthService {
  String? _mockSpotifyToken;
  String? _mockRefreshResult;

  MockAuthService({String? initialToken, String? refreshResult}) {
    _mockSpotifyToken = initialToken;
    _mockRefreshResult = refreshResult;
  }

  @override
  String? get spotifyAccessToken => _mockSpotifyToken;

  void setMockToken(String? token) {
    _mockSpotifyToken = token;
  }

  void setMockRefreshResult(String? result) {
    _mockRefreshResult = result;
  }

  @override
  Future<String?> refreshSpotifyToken() async {
    if (_mockRefreshResult != null) {
      _mockSpotifyToken = _mockRefreshResult;
    }
    return _mockRefreshResult;
  }
}

/// A simple mock implementation of AuthTokenProvider for testing
class MockAuthTokenProvider implements AuthTokenProvider {
  String? _accessToken;
  String? _refreshResult;
  int refreshCallCount = 0;

  MockAuthTokenProvider({String? accessToken, String? refreshResult})
      : _accessToken = accessToken,
        _refreshResult = refreshResult;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> refreshToken() async {
    refreshCallCount++;
    if (_refreshResult != null) {
      _accessToken = _refreshResult;
    }
    return _refreshResult;
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void setRefreshResult(String? result) {
    _refreshResult = result;
  }
}

void main() {
  group('AuthTokenProvider interface', () {
    test('MockAuthTokenProvider implements AuthTokenProvider correctly', () async {
      final provider = MockAuthTokenProvider(
        accessToken: 'test-token',
        refreshResult: 'new-token',
      );

      // Test getAccessToken
      expect(await provider.getAccessToken(), equals('test-token'));

      // Test refreshToken
      final refreshedToken = await provider.refreshToken();
      expect(refreshedToken, equals('new-token'));
      expect(provider.refreshCallCount, equals(1));

      // After refresh, getAccessToken should return new token
      expect(await provider.getAccessToken(), equals('new-token'));
    });

    test('MockAuthTokenProvider returns null when no token', () async {
      final provider = MockAuthTokenProvider();

      expect(await provider.getAccessToken(), isNull);
      expect(await provider.refreshToken(), isNull);
    });
  });

  group('SpotifyAuthTokenProvider', () {
    test('getAccessToken returns AuthService spotifyAccessToken', () async {
      final mockAuthService = MockAuthService(initialToken: 'spotify-access-token');
      final provider = SpotifyAuthTokenProvider(mockAuthService);

      final token = await provider.getAccessToken();
      expect(token, equals('spotify-access-token'));
    });

    test('getAccessToken returns null when not authenticated', () async {
      final mockAuthService = MockAuthService();
      final provider = SpotifyAuthTokenProvider(mockAuthService);

      final token = await provider.getAccessToken();
      expect(token, isNull);
    });

    test('refreshToken calls AuthService refreshSpotifyToken', () async {
      final mockAuthService = MockAuthService(
        initialToken: 'old-token',
        refreshResult: 'new-refreshed-token',
      );
      final provider = SpotifyAuthTokenProvider(mockAuthService);

      final refreshedToken = await provider.refreshToken();
      expect(refreshedToken, equals('new-refreshed-token'));
    });

    test('refreshToken returns null when refresh fails', () async {
      final mockAuthService = MockAuthService(initialToken: 'old-token');
      final provider = SpotifyAuthTokenProvider(mockAuthService);

      final refreshedToken = await provider.refreshToken();
      expect(refreshedToken, isNull);
    });

    test('after successful refresh, getAccessToken returns new token', () async {
      final mockAuthService = MockAuthService(
        initialToken: 'old-token',
        refreshResult: 'new-refreshed-token',
      );
      final provider = SpotifyAuthTokenProvider(mockAuthService);

      // Initial token
      expect(await provider.getAccessToken(), equals('old-token'));

      // After refresh
      await provider.refreshToken();
      expect(await provider.getAccessToken(), equals('new-refreshed-token'));
    });
  });
}
