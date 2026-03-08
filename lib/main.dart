import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/income_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/shopping_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/inventory_provider.dart';
import 'services/voice_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es', null);

  // Inicializar el controlador de voz global antes de la UI
  final voiceController = VoiceController();
  await voiceController.init();

  runApp(MyApp(voiceController: voiceController));
}

class MyApp extends StatelessWidget {
  final VoiceController voiceController;
  const MyApp({super.key, required this.voiceController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: voiceController),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'A la Orden Jefe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
