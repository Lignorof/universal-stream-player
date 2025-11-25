
import 'package:flutter/material.dart';
// Importe ambos os modelos
import '../model/stream_playlist.dart'; 
import '../model/stream_track.dart';
import '../core/spotify_api_service.dart';

class LibraryScreen extends StatefulWidget {
  final String accessToken;
  const LibraryScreen({super.key, required this.accessToken});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

// Adiciona 'with SingleTickerProviderStateMixin' para o TabController
class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final SpotifyApiService _apiService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _apiService = SpotifyApiService(widget.accessToken);
    // Inicializa o TabController com 2 abas
    _tabController = TabController(length: 2, vsync: this); 
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
        // Adiciona a TabBar no 'bottom' da AppBar
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Permite rolar as abas se houver muitas
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Músicas Curtidas'),
            // Adicione 'Artistas' e 'Álbuns' aqui quando implementar
          ],
        ),
      ),
      // Usa um TabBarView para sincronizar o conteúdo com as abas
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Conteúdo da Aba de Playlists ---
          _buildFutureList<StreamPlaylist>(
            future: _apiService.getCurrentUserPlaylists(),
            itemBuilder: (playlist) => ListTile(
              leading: playlist.imageUrl.isNotEmpty 
                  ? Image.network(playlist.imageUrl, width: 50, height: 50, fit: BoxFit.cover) 
                  : const Icon(Icons.queue_music, size: 40),
              title: Text(playlist.name),
              subtitle: Text('de ${playlist.owner}'),
            ),
          ),

          // --- Conteúdo da Aba de Músicas Curtidas (NOVO) ---
          _buildFutureList<StreamTrack>(
            future: _apiService.getSavedTracks(),
            itemBuilder: (track) => ListTile(
              leading: track.imageUrl.isNotEmpty 
                  ? Image.network(track.imageUrl, width: 50, height: 50, fit: BoxFit.cover) 
                  : const Icon(Icons.music_note, size: 40),
              title: Text(track.name),
              subtitle: Text('${track.artist} • ${track.albumName}'),
            ),
          ),
        ],
      ),
    );
  }

  // Widget genérico para lidar com o estado de Future (sem alterações)
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
          return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
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

