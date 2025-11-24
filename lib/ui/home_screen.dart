import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Universal Stream Player'),
            actions: [
              if (authService.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () => authService.logout(),
                ),
            ],
          ),
          body: Center(
            child: authService.isAuthenticated
                ? _buildAuthenticatedUI(context, authService)
                : _buildLoginUI(context, authService),
          ),
        );
      },
    );
  }

  Widget _buildLoginUI(BuildContext context, AuthService authService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Bem-vindo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        
        // Botão de Login do Spotify
        ElevatedButton.icon(
          icon: const Icon(Icons.music_note), // Ícone genérico ou do Spotify
          label: const Text('Login com Spotify'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            minimumSize: const Size(250, 50),
          ),
          onPressed: () async {
            try { await authService.loginSpotify(); } 
            catch (e) { _showErrorSnackbar(context, e.toString()); }
          },
        ),
        const SizedBox(height: 20),

        // --- BOTÃO DO DEEZER ADICIONADO ---
        ElevatedButton.icon(
          icon: const Icon(Icons.album), // Ícone genérico ou do Deezer
          label: const Text('Login com Deezer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[700], foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            minimumSize: const Size(250, 50),
          ),
          onPressed: () async {
            try { await authService.loginDeezer(); } 
            catch (e) { _showErrorSnackbar(context, e.toString()); }
          },
        ),
      ],
    );
  }

  Widget _buildAuthenticatedUI(BuildContext context, AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (authService.isSpotifyAuthenticated) ...[
            const Text('Conectado ao Spotify!', style: TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 20),
          ],
          if (authService.isDeezerAuthenticated) ...[
            const Text('Conectado ao Deezer!', style: TextStyle(fontSize: 20, color: Colors.lightBlue)),
            const SizedBox(height: 20),
          ],
          const Text('Agora você pode implementar a busca de músicas e playlists.'),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

