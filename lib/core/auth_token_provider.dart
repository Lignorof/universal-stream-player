/// Abstract interface for authentication token providers.
///
/// This interface centralizes token management (access/refresh) so that
/// API services can retrieve and refresh tokens in a consistent manner,
/// making authentication usage easier to test and maintain.
abstract class AuthTokenProvider {
  /// Returns the current access token, or null if not authenticated.
  Future<String?> getAccessToken();

  /// Attempts to refresh the access token.
  ///
  /// Returns the new access token if refresh was successful, or null if
  /// the refresh failed (e.g., no refresh token available, token expired).
  Future<String?> refreshToken();
}
