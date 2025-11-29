import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/core/spotify_api_service.dart';
import 'package:universal_stream_player/core/stream_playlist.dart';
import 'package:universal_stream_player/core/stream_track.dart';
import 'package:universal_stream_player/core/audio_player_service.dart';

class PlaylistScreen extends StatefulWidget {
  final StreamPlaylist playlist;
  // CORREÇÃO: Recebe o AuthService completo
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
    // Usa o authService recebido para criar o SpotifyApiService
    final spotifyService = SpotifyApiService(
      widget.authService.spotifyAccessToken!,
      widget.authService,
    );
    _tracksFuture = spotifyService.getPlaylistTracks(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
      ),
      body: FutureBuilder<List<StreamTrack>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar músicas: ${snapshot.error}'));
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

