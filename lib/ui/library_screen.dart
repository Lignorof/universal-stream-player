import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/stream_playlist.dart';
import '../core/deezer_api_service.dart';
import '../core/stream_track.dart';
import '../core/spotify_api_service.dart';
import '../core/audio_player_service.dart'; // CORREÇÃO: Importar o serviço de áudio
import 'playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<StreamPlaylist>>? _combinedPlaylistsFuture;
  Future<List<StreamTrack>>? _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authService = context.read<AuthService>();
    setState(() {
      _combinedPlaylistsFuture = _loadCombinedPlaylists(authService);
      if (authService.isSpotifyAuthenticated) {
        final spotifyService = SpotifyApiService(authService.spotifyAccessToken!, authService);
        _tracksFuture = spotifyService.getSavedTracks();
      }
    });
  }

  Future<List<StreamPlaylist>> _loadCombinedPlaylists(AuthService authService) async {
    List<StreamPlaylist> combinedList = [];

    if (authService.isSpotifyAuthenticated) {
      final spotifyService = SpotifyApiService(authService.spotifyAccessToken!, authService);
      try {
        final spotifyPlaylists = await spotifyService.getCurrentUserPlaylists();
        combinedList.addAll(spotifyPlaylists);
      } catch (e) {
        print("Erro ao carregar playlists do Spotify: $e");
      }
    }

    if (authService.isDeezerAuthenticated) {
      final deezerService = DeezerApiService(authService.deezerAccessToken!);
      try {
        final deezerPlaylists = await deezerService.getCurrentUserPlaylists();
        combinedList.addAll(deezerPlaylists);
      } catch (e) {
        print("Erro ao carregar playlists do Deezer: $e");
      }
    }

    combinedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return combinedList;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Biblioteca'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Músicas Curtidas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba de Playlists
          _buildFutureList<StreamPlaylist>(
            future: _combinedPlaylistsFuture,
            itemBuilder: (playlist) => ListTile(
              leading: playlist.imageUrl.isNotEmpty
                  ? Image.network(playlist.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.queue_music, size: 40),
              title: Text(playlist.name),
              subtitle: Text('de ${playlist.owner} (${playlist.source})'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistScreen(
                      playlist: playlist,
                      // CORREÇÃO: Passa o authService, como o construtor agora espera
                      authService: context.read<AuthService>(),
                    ),
                  ),
                );
              },
            ),
          ),
          // Aba de Músicas Curtidas
          _buildFutureList<StreamTrack>(
            future: _tracksFuture,
            itemBuilder: (track) => ListTile(
              leading: track.imageUrl.isNotEmpty
                  ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.music_note, size: 40),
              title: Text(track.name),
              subtitle: Text('${track.artist} • ${track.albumName}'),
              onTap: () {
                // CORREÇÃO: Acessa o AudioPlayerService através do Provider
                context.read<AudioPlayerService>().play(track);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureList<T>({
    required Future<List<T>>? future,
    required Widget Function(T item) itemBuilder,
  }) {
    if (future == null) {
      return const Center(child: Text('Faça login para ver o conteúdo.'));
    }
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum item encontrado.'));
        }
        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}

