import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/audio_player_service.dart';
import 'library_screen.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          body: authService.isAuthenticated
              ? const LibraryScreen()
              : const LoginScreen(),
          bottomNavigationBar:
              authService.isAuthenticated ? const MiniPlayer() : null,
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _login(BuildContext context, Future<void> Function() loginMethod) async {
    try {
      await loginMethod();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bem-vindo ao Universal Stream Player', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954), // Cor do Spotify
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              onPressed: () => _login(context, authService.loginSpotify),
              child: const Text('Login com Spotify'),
            ),
            const SizedBox(height: 16),
            const Text('ou'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEAA2D), // Cor do Deezer
                foregroundColor: Colors.black,
                minimumSize: const Size(200, 50),
              ),
              onPressed: () => _login(context, authService.loginDeezer),
              child: const Text('Login com Deezer'),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  static bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final audioPlayer = context.watch<AudioPlayerService>();
    final track = audioPlayer.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration?>(
                stream: audioPlayer.durationStream.map((d) => d ?? Duration.zero),
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final total = durationSnapshot.data ?? Duration.zero;
                  return ProgressBar(
                    progress: position,
                    total: total,
                    onSeek: audioPlayer.seek,
                    barHeight: 3,
                    thumbRadius: 5,
                  );
                },
              );
            },
          ),
          Expanded(
            child: Row(
              children: [
                Image.network(track.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(track.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(track.artist, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
                if (_isDesktop)
                  SizedBox(
                    width: 150,
                    child: StreamBuilder<double>(
                      stream: audioPlayer.volumeStream,
                      builder: (context, snapshot) {
                        final volume = snapshot.data ?? 1.0;
                        return Row(
                          children: [
                            Icon(volume > 0.5 ? Icons.volume_up : (volume > 0 ? Icons.volume_down : Icons.volume_mute)),
                            Expanded(
                              child: Slider(
                                value: volume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: audioPlayer.setVolume,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                StreamBuilder<PlayerState>(
                  stream: audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState?.playing ?? false;
                    final processingState = playerState?.processingState;
                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                      return const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2))));
                    }
                    return IconButton(
                      iconSize: 32,
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      onPressed: isPlaying ? audioPlayer.pause : audioPlayer.resume,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

