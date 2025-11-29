import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/audio_player_service.dart';
import '../core/stream_playlist.dart';
import '../core/stream_track.dart';
import '../core/spotify_api_service.dart';

class PlaylistScreen extends StatefulWidget {
  final StreamPlaylist playlist;
  final String accessToken;

  const PlaylistScreen({super.key, required this.playlist, required this.accessToken});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late final SpotifyApiService _apiService;
  late Future<List<StreamTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiService = SpotifyApiService(widget.accessToken, authService);
    _tracksFuture = _apiService.getPlaylistTracks(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = context.read<AudioPlayerService>();
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
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          
          // --- CORREÇÃO ---
          // Filtra as músicas que foram marcadas como não tocáveis.
          final tracks = snapshot.data?.where((track) => track.isPlayable).toList() ?? [];

          if (tracks.isEmpty) {
            return const Center(child: Text('Esta playlist está vazia ou as músicas não estão disponíveis.'));
          }
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return ListTile(
                leading: track.imageUrl.isNotEmpty
                    ? Image.network(track.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.music_note),
                title: Text(track.name),
                subtitle: Text(track.artist),
                onTap: () {
                  // O onTap já é seguro porque a lista só contém faixas tocáveis.
                  audioPlayer.play(track);
                },
              );
            },
          );
        },
      ),
    );
  }
}

