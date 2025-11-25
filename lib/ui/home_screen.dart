import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/audio_player_service.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' aqui para que a tela se reconstrua quando o estado de auth mudar.
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: Column(
        children: [
          // O conteúdo principal (Login ou Biblioteca)
          Expanded(
            child: authService.isAuthenticated
                ? LibraryScreen(accessToken: authService.spotifyAccessToken!)
                : _buildLoginUI(context, authService),
          ),
          // O Mini-Player persistente na parte inferior
          const MiniPlayer(),
        ],
      ),
    );
  }

  /// Constrói a UI de login quando o usuário não está autenticado.
  Widget _buildLoginUI(BuildContext context, AuthService authService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bem-vindo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          // Botão de Login do Spotify
          ElevatedButton.icon(
            icon: const Icon(Icons.music_note),
            label: const Text('Login com Spotify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              minimumSize: const Size(250, 50),
            ),
            onPressed: () async {
              try {
                await authService.loginSpotify();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro no login: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 20),

          // Botão de Login do Deezer
          ElevatedButton.icon(
            icon: const Icon(Icons.album),
            label: const Text('Login com Deezer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[700], foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              minimumSize: const Size(250, 50),
            ),
            onPressed: () async {
              try {
                await authService.loginDeezer();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro no login com Deezer: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// O Widget do Mini-Player que aparece na parte inferior da tela.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  // Variável estática para detectar se estamos em uma plataforma desktop.
  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' aqui para que o player se reconstrua quando a música mudar.
    final audioPlayer = context.watch<AudioPlayerService>();
    final track = audioPlayer.currentTrack;

    // Se nenhuma música foi selecionada, não mostra nada.
    if (track == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 65, // Altura fixa para o mini-player
      color: Colors.grey[850],
      child: Row(
        children: [
          // Imagem da música
          track.imageUrl.isNotEmpty
              ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.music_note, size: 50),
          const SizedBox(width: 12),

          // Título e Artista
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

          // --- CONTROLE DE VOLUME (Condicional para Desktop) ---
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
          // ----------------------------------------------------

          // Botão de Play/Pause
          StreamBuilder<PlayerState>(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              final processingState = playerState?.processingState;

              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                return const SizedBox(
                  width: 48, height: 48,
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                );
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
    );
  }
}

