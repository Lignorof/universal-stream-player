import 'package:flutter/material.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/ui/home_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Universal Stream Player',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                icon: const Icon(Icons.music_note),
                label: const Text('Login com Spotify'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _login(context, authService.loginSpotify),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.album),
                label: const Text('Login com Deezer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _login(context, authService.loginDeezer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login(BuildContext context, Future<void> Function() loginMethod) async {
    try {
      await loginMethod();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => HomeScreen(authService: authService)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro no login: $e')));
    }
  }
}
