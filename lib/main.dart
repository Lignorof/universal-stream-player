import 'package:flutter/material.dart';
import 'package:universal_stream_player/core/auth_service.dart';
import 'package:universal_stream_player/ui/home_screen.dart';
import 'package:universal_stream_player/ui/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(const UniversalStreamPlayerApp());
}

class UniversalStreamPlayerApp extends StatefulWidget {
  const UniversalStreamPlayerApp({super.key});

  @override
  State<UniversalStreamPlayerApp> createState() => _UniversalStreamPlayerAppState();
}

class _UniversalStreamPlayerAppState extends State<UniversalStreamPlayerApp> {
  final AuthService _authService = AuthService();
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _authService.loadAllTokens();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Stream Player',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Se o usuário estiver autenticado em qualquer serviço, vai para a home.
            return _authService.isAuthenticated
                ? HomeScreen(authService: _authService)
                : LoginScreen(authService: _authService);
          }
          // Tela de carregamento enquanto os tokens são verificados
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
