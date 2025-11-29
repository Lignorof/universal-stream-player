import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';
import '../core/audio_player_service.dart';
import '../core/stream_playlist.dart';
import '../core/stream_track.dart';
import '../core/spotify_api_service.dart';
import 'playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  final String accessToken;
  const LibraryScreen({super.key, required this.accessToken});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final SpotifyApiService _apiService;
  late final TabController _tabController;

  // Variável para detectar se estamos no desktop
  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiService = SpotifyApiService(widget.accessToken, authService);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = context.read<AudioPlayerService>();
    final authService = context.read<AuthService>();

    return Scaffold(
      // --- NOVO: Drawer (Hamburger Menu) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey),
              child: Text('Menu', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Navegar para a tela de configurações
                Navigator.pop(context); // Fecha o drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log out'),
              onTap: () {
                authService.logout();
                // O Navigator.pop(context) não é necessário aqui, pois o logout
                // fará com que a HomeScreen se reconstrua e mostre a tela de login.
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Sua Biblioteca'),
        // --- NOVO: Botão de Sair para Desktop ---
        actions: [
          if (_isDesktop)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close to desktop',
              onPressed: () {
                // Fecha o aplicativo
                SystemNavigator.pop();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Músicas Curtidas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Conteúdo da Aba de Playlists
          _buildFutureList<StreamPlaylist>(
            future: _apiService.getCurrentUserPlaylists(),
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
                      accessToken: widget.accessToken,
                    ),
                  ),
                );
              },
            ),
          ),
          // Conteúdo da Aba de Músicas Curtidas
          _buildFutureList<StreamTrack>(
            future: _apiService.getSavedTracks(),
            itemBuilder: (track) => ListTile(
              leading: track.imageUrl.isNotEmpty
                  ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.music_note, size: 40),
              title: Text(track.name),
              subtitle: Text('${track.artist} • ${track.albumName}'),
              onTap: () {
                audioPlayer.play(track);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureList<T>({
    required Future<List<T>> future,
    required Widget Function(T item) itemBuilder,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Exibe o erro de forma mais clara
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  const Text('Ocorreu um erro:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Força um novo login ao fazer logout
                      context.read<AuthService>().logout();
                    },
                    child: const Text('Fazer login novamente'),
                  )
                ],
              ),
            ),
          );
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

