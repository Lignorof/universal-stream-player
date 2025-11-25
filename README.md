# Universal Stream Player

A Flutter music player application that integrates multiple streaming services into a single, unified interface. Stream your favorite music from Spotify, Deezer, and more, all in one place.

## Features

- 🎵 **Multi-Platform Streaming**: Access music from Spotify and Deezer in one app
- 🔐 **Secure Authentication**: OAuth2 with PKCE flow for secure login
- 📱 **Cross-Platform**: Built with Flutter for iOS, Android, Linux, macOS, Windows, and Web
- 🎨 **Unified Interface**: Consistent experience across all streaming services
- 📂 **Playlist Management**: Browse and manage playlists from different services
- 🎧 **Integrated Player**: Built-in audio player for seamless playback

## Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Linux
- ✅ macOS
- ✅ Windows
- ✅ Web

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.2.0)
- [Dart SDK](https://dart.dev/get-dart) (>= 3.2.0)
- IDE (VS Code, Android Studio, or IntelliJ IDEA)

### API Credentials

You'll need to register your application with the following services:

1. **Spotify**: Get your Client ID from [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/)
2. **Deezer**: Get your Application ID from [Deezer Developers](https://developers.deezer.com/myapps)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/LuqP2/universal-stream-player.git
   cd universal-stream-player
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add your API credentials:
   ```env
   # --- Spotify ---
   SPOTIFY_CLIENT_ID=your_spotify_client_id_here

   # --- Deezer ---
   DEEZER_APP_ID=your_deezer_app_id_here
   ```

## Running the App

### Development Mode

Run on your connected device or emulator:

```bash
flutter run
```

### Specific Platform

```bash
# Android
flutter run -d android

# iOS (requires macOS)
flutter run -d ios

# Linux
flutter run -d linux

# macOS (requires macOS)
flutter run -d macos

# Windows
flutter run -d windows

# Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                      # Application entry point
├── api/                           # API service integrations
│   ├── spotify_api_service.dart   # Spotify API client
│   └── deezer_api_service.dart    # Deezer API client
├── core/                          # Core services
│   ├── auth_service.dart          # OAuth2 authentication
│   ├── audio_player_service.dart  # Audio playback management
│   └── database_service.dart      # Local data persistence
├── models/                        # Data models
│   ├── stream_track.dart          # Track model
│   └── stream_playlist.dart       # Playlist model
└── ui/                            # User interface screens
    ├── home_screen.dart           # Main home screen
    ├── login_screen.dart          # Authentication screen
    └── playlist_screen.dart       # Playlist view
```

## Technologies Used

- **Framework**: [Flutter](https://flutter.dev/) - Cross-platform UI framework
- **State Management**: [Provider](https://pub.dev/packages/provider) - Simple state management
- **Authentication**: OAuth2 with PKCE flow
- **HTTP Client**: [http](https://pub.dev/packages/http) - API requests
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) - Data persistence
- **Environment Config**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) - Environment variable management

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS (requires macOS and Xcode)
```bash
flutter build ios --release
```

### Linux
```bash
flutter build linux --release
```

### macOS (requires macOS)
```bash
flutter build macos --release
```

### Windows
```bash
flutter build windows --release
```

### Web
```bash
flutter build web --release
```

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available under the [MIT License](LICENSE).

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.

---

**Note**: This application requires active API keys from Spotify and Deezer. Make sure to comply with their respective Terms of Service and API usage guidelines.
