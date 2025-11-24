import 'package:flutter/material.dart';
import 'package:universal_stream_player/api/spotify_api_service.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/core/database_service.dart';
import 'package:universal_stream_player/models/stream_playlist.dart';
import 'package:universal_stream_player/ui/playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  const HomeScreen({super.key, required this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StreamPlaylist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() { _isLoading = true; });

    // 1. Carrega do cache primeiro para uma UI rápida
    final cachedPlaylists = await DatabaseService.instance.getCachedPlaylists();
    if (mounted) {
      setState(() {
        _playlists = cachedPlaylists;
        _isLoading = false; // Permite que a UI mostre os dados cacheados
      });
    }

    // 2. Em segundo plano, busca na API por atualizações
    try {
      List<StreamPlaylist> freshPlaylists = [];
      if (widget.authService.isSpotifyAuthenticated) {
        final spotifyService = SpotifyApiService(widget.authService.spotifyAccessToken!);
        freshPlaylists.addAll(await spotifyService.fetchUserPlaylists());
      }
      // Adicionar aqui a busca de playlists do Deezer se necessário

      // 3. Atualiza o cache e a UI
      await DatabaseService.instance.cachePlaylists(freshPlaylists);
      if (mounted) {
        setState(() {
          _playlists = freshPlaylists;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sincronizar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Playlists'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists)],
      ),
      body: _isLoading && _playlists.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlaylists,
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    leading: playlist.imageUrl.isNotEmpty
                        ? Image.network(playlist.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, size: 50),
                    title: Text(playlist.name),
                    subtitle: Text('por ${playlist.owner} • ${playlist.source}'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlaylistScreen(
                          playlist: playlist,
                          authService: widget.authService,
                        ),
                      ));
                    },
                  );
                },
              ),
            ),
    );
  }
}
