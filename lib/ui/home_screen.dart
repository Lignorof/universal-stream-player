import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/audio_player_service.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          body: authService.isSpotifyAuthenticated
              ? LibraryScreen(accessToken: authService.spotifyAccessToken!)
              : const LoginScreen(),
          bottomNavigationBar: authService.isSpotifyAuthenticated ? const MiniPlayer() : null,
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.music_note),
            label: const Text('Login com Spotify'),
            onPressed: () async {
              try {
                await authService.loginSpotify();
              } catch (e) {
                _showError(context, e.toString());
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.album),
            label: const Text('Login com Deezer'),
            onPressed: () async {
              try {
                await authService.loginDeezer();
              } catch (e) {
                _showError(context, e.toString());
              }
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET MiniPlayer ATUALIZADO ---
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // Função para formatar a duração (ex: 01:23)
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = context.watch<AudioPlayerService>();
    final track = audioPlayer.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- NOSSA PRÓPRIA BARRA DE PROGRESSO ---
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                // CORREÇÃO: Mapeia o stream para substituir null por Duration.zero
                stream: audioPlayer.durationStream.map((d) => d ?? Duration.zero),
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                            min: 0.0,
                            max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                            onChanged: (value) {
                              audioPlayer.seek(Duration(milliseconds: value.round()));
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey[700],
                          ),
                        ),
                        Text(_formatDuration(duration), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // ---------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 4.0),
            child: Row(
              children: [
                track.imageUrl.isNotEmpty
                    ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.music_note, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_isDesktop)
                  SizedBox(
                    width: 150,
                    child: StreamBuilder<double>(
                      stream: audioPlayer.volumeStream,
                      builder: (context, snapshot) {
                        final volume = snapshot.data ?? 1.0;
                        return Row(
                          children: [
                            Icon(volume > 0.5 ? Icons.volume_up : (volume > 0 ? Icons.volume_down : Icons.volume_mute), size: 20),
                            Expanded(
                              child: Slider(
                                value: volume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: audioPlayer.setVolume,
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                StreamBuilder<bool>(
                  stream: audioPlayer.isPlayingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
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

