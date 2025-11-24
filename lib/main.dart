
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; // Exemplo usando Provider para gerenciar o estado
import 'core/auth_service.dart';
import 'ui/home_screen.dart'; // Supondo que você tenha uma tela inicial

Future<void> main() async {
  // Garante que os widgets do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega as variáveis de ambiente do arquivo .env
  await dotenv.load(fileName: ".env");
  
  runApp(const UniversalStreamPlayerApp());
}

class UniversalStreamPlayerApp extends StatelessWidget {
  const UniversalStreamPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar um ChangeNotifierProvider é uma boa prática para gerenciar o AuthService
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Universal Stream Player',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

