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
                  onPressed: () {
                    authService.logout();
                  },
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
        const Text(
          'Bem-vindo!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Login com Spotify'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: () async {
            try {
              await authService.loginSpotify();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro no login: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
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
          const Text(
            'Login bem-sucedido!',
            style: TextStyle(fontSize: 22, color: Colors.green),
          ),
          const SizedBox(height: 20),
          const Text('Agora você pode implementar a busca de músicas e playlists.'),
          const SizedBox(height: 40),
          const Text(
            'Seu Access Token (sensível, não exiba em um app real):',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(
            authService.accessToken ?? 'Nenhum token encontrado',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

