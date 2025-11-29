import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/stream_playlist.dart';
import '../core/stream_track.dart';
import '../core/spotify_api_service.dart';
import '../core/audio_player_service.dart';

class PlaylistScreen extends StatefulWidget {
  final StreamPlaylist playlist;
  // CORREÇÃO: Recebe o AuthService inteiro
  final AuthService authService;

  const PlaylistScreen({
    super.key,
    required this.playlist,
    required this.authService,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Future<List<StreamTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    // Por enquanto, só sabemos carregar tracks do Spotify
    if (widget.playlist.source == 'spotify' && widget.authService.isSpotifyAuthenticated) {
      final spotifyService = SpotifyApiService(widget.authService.spotifyAccessToken!, widget.authService);
      _tracksFuture = spotifyService.getPlaylistTracks(widget.playlist.id);
    } else {
      // Se a playlist for do Deezer ou o usuário não estiver logado no Spotify,
      // retorna uma lista vazia por enquanto.
      _tracksFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: FutureBuilder<List<StreamTrack>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma música encontrada nesta playlist.'));
          }
          final tracks = snapshot.data!;
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: track.imageUrl.isNotEmpty
                    ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.music_note, size: 40),
                title: Text(track.name),
                subtitle: Text(track.artist),
                onTap: () {
                  // Usa o Provider para acessar o AudioPlayerService
                  context.read<AudioPlayerService>().play(track);
                },
              );
            },
          );
        },
      ),
    );
  }
}

