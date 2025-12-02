import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/auth_service.dart';
import 'core/audio_player_service.dart';
import 'ui/home_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
      ],
      child: const UniversalStreamPlayerApp(),
    ),
  );
}

class UniversalStreamPlayerApp extends StatelessWidget {
  const UniversalStreamPlayerApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Obtain the AuthService instance from Provider and pass it into HomeScreen.
    final authService = Provider.of<AuthService>(context, listen: false);

    return MaterialApp(
      title: 'Universal Stream Player',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(authService: authService),
    );
  }
}
