import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'providers/income_provider.dart';
import 'providers/bills_provider.dart';

import 'voice/voice_service.dart';

// Pantallas
import 'screens/home_screen.dart';
import 'screens/bills/bills_screen.dart';
import 'screens/income/income_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('es', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: MaterialApp(
        title: 'Orden',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
          useMaterial3: true,
        ),

        // Pantalla inicial
        home: const HomeScreen(),

        // RUTAS PARA VOZ
        routes: {
          '/bills': (context) => const BillsScreen(),
          '/income': (context) => const IncomeScreen(),
        },
      ),
    );
  }
}
