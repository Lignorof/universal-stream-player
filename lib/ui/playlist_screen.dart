import 'package:flutter/material.dart';
import 'package:universal_stream_player/api/spotify_api_service.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/core/audio_player_service.dart';
import 'package:universal_stream_player/core/database_service.dart';
import 'package:universal_stream_player/models/stream_playlist.dart';
import 'package:universal_stream_player/models/stream_track.dart';

class PlaylistScreen extends StatefulWidget {
  final StreamPlaylist playlist;
  final AuthService authService;

  const PlaylistScreen({super.key, required this.playlist, required this.authService});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  List<StreamTrack> _tracks = [];
  bool _isLoading = true;
  StreamTrack? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    setState(() { _isLoading = true; });

    // 1. Carrega do cache
    final cachedTracks = await DatabaseService.instance.getCachedTracks(widget.playlist.id);
    if (mounted) {
      setState(() {
        _tracks = cachedTracks;
        _isLoading = false;
      });
    }

    // 2. Busca na API
    try {
      List<StreamTrack> freshTracks = [];
      if (widget.playlist.source == 'spotify' && widget.authService.isSpotifyAuthenticated) {
        final spotifyService = SpotifyApiService(widget.authService.spotifyAccessToken!);
        freshTracks = await spotifyService.fetchPlaylistTracks(widget.playlist.id);
      }
      // Adicionar aqui a busca de tracks do Deezer se necessário

      // 3. Atualiza cache e UI
      await DatabaseService.instance.cacheTracks(widget.playlist.id, freshTracks);
      if (mounted) {
        setState(() {
          _tracks = freshTracks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sincronizar músicas: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onPlay(StreamTrack track) {
    _audioPlayer.play(track.name, track.artist).then((_) {
      if (mounted) setState(() => _currentlyPlaying = track);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _tracks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTracks,
                    child: ListView.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        final isPlaying = _currentlyPlaying?.name == track.name && _currentlyPlaying?.artist == track.artist;
                        return ListTile(
                          leading: track.imageUrl.isNotEmpty
                              ? Image.network(track.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                              : const Icon(Icons.album, size: 40),
                          title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: isPlaying ? const Icon(Icons.volume_up, color: Colors.greenAccent) : null,
                          onTap: () => _onPlay(track),
                        );
                      },
                    ),
                  ),
          ),
          if (_currentlyPlaying != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      child: ListTile(
        leading: _currentlyPlaying!.imageUrl.isNotEmpty
            ? Image.network(_currentlyPlaying!.imageUrl)
            : const Icon(Icons.album),
        title: Text(_currentlyPlaying!.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(_currentlyPlaying!.artist, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.stop_circle_outlined),
          iconSize: 32,
          onPressed: () {
            _audioPlayer.stop();
            if (mounted) setState(() => _currentlyPlaying = null);
          },
        ),
      ),
    );
  }
}
