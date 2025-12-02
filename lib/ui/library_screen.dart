import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/core/spotify_auth_token_provider.dart';
import 'package:universal_stream_player/core/stream_playlist.dart';
import 'package:universal_stream_player/core/stream_track.dart';
import 'package:universal_stream_player/core/youtube_music_api_service.dart';
import 'package:universal_stream_player/core/spotify_api_service.dart';
import 'package:universal_stream_player/core/audio_player_service.dart';
import 'package:universal_stream_player/ui/playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SpotifyApiService _spotifyService;
  Future<List<StreamPlaylist>>? _playlistsFuture;
  Future<List<StreamTrack>>? _tracksFuture;

  final TextEditingController _searchController = TextEditingController();
  Future<List<StreamTrack>>? _searchFuture;
  final YoutubeMusicApiService _youtubeService = YoutubeMusicApiService();

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final tokenProvider = SpotifyAuthTokenProvider(authService);
    _spotifyService = SpotifyApiService(tokenProvider);
    _tabController = TabController(length: 2, vsync: this);
    _loadLibraryData();
  }

  void _loadLibraryData() {
    setState(() {
      _playlistsFuture = _spotifyService.getCurrentUserPlaylists();
      _tracksFuture = _spotifyService.getSavedTracks();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchFuture = _youtubeService.searchTracks(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchFuture = null;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _youtubeService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchFuture == null ? const Text('Sua Biblioteca') : null,
        flexibleSpace: _searchFuture != null ? SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 56.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar músicas...',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ) : null,
        actions: _searchFuture == null ? [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchFuture = Future.value([]);
              });
            },
          )
        ] : null,
        bottom: _searchFuture == null ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Músicas Curtidas'),
          ],
        ) : null,
      ),
      drawer: const AppDrawer(),
      body: _searchFuture != null
        ? _buildSearchResults()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildFutureList<StreamPlaylist>(
                future: _playlistsFuture,
                itemBuilder: (playlist) => ListTile(
                  leading: playlist.imageUrl.isNotEmpty
                      ? Image.network(playlist.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.queue_music, size: 40),
                  title: Text(playlist.name),
                  subtitle: Text('de ${playlist.owner}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistScreen(
                          playlist: playlist,
                          // CORREÇÃO: Passa o AuthService inteiro
                          authService: context.read<AuthService>(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildFutureList<StreamTrack>(
                future: _tracksFuture,
                itemBuilder: (track) => ListTile(
                  leading: track.imageUrl.isNotEmpty
                      ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.music_note, size: 40),
                  title: Text(track.name),
                  subtitle: Text(track.artist),
                  onTap: () {
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

  Widget _buildSearchResults() {
    return FutureBuilder<List<StreamTrack>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ocorreu um erro na busca: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum resultado encontrado.'));
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
              trailing: Icon(
                track.source == 'spotify' ? Icons.graphic_eq : Icons.play_circle_outline,
                color: track.source == 'spotify' ? Colors.green : Colors.red,
              ),
              onTap: () => context.read<AudioPlayerService>().play(track),
            );
          },
        );
      },
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey),
            child: Text('Universal Stream Player', style: TextStyle(fontSize: 24, color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              context.read<AuthService>().logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

