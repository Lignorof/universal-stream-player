import 'auth_service.dart';
import 'auth_token_provider.dart';

/// Adapter that wraps [AuthService] to implement [AuthTokenProvider]
/// for Spotify authentication.
///
/// This allows [SpotifyApiService] to depend on the abstract interface
/// rather than directly on [AuthService], making it easier to test and
/// swap implementations.
class SpotifyAuthTokenProvider implements AuthTokenProvider {
  final AuthService _authService;

  SpotifyAuthTokenProvider(this._authService);

  @override
  Future<String?> getAccessToken() async {
    return _authService.spotifyAccessToken;
  }

  @override
  Future<String?> refreshToken() async {
    return _authService.refreshSpotifyToken();
  }
}
