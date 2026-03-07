import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/email_verification_screen.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const OrdenApp());
}

class OrdenApp extends StatelessWidget {
  const OrdenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(repo: AuthRepositoryImpl())),
        // Aquí se añadirán los providers de los otros módulos:
        // ChangeNotifierProvider(create: (_) => InventoryProvider()),
        // ChangeNotifierProvider(create: (_) => IncomeProvider()),
        // etc.
      ],
      child: MaterialApp(
        title: 'Orden',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primario,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.fondo,
          fontFamily: 'Roboto',
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Árbol de decisión de navegación basado en el estado de autenticación.
///
/// Este widget es el único punto de la app que decide qué pantalla
/// mostrar según [AuthStatus]. Las pantallas individuales **nunca** navegan
/// directamente al Home; dejan que este wrapper reaccione al stream.
///
/// Estados manejados:
/// - [AuthStatus.inicial]       → splash con indicador de carga
/// - [AuthStatus.autenticado]   → si emailVerificado: HomeScreen, si no: EmailVerificationScreen
/// - cualquier otro             → LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.inicial:
            return const _SplashScreen();

          case AuthStatus.autenticado:
            // Si el email no está verificado, mostrar pantalla de verificación
            final verificado = auth.usuario?.emailVerificado ?? false;
            if (!verificado) {
              return const EmailVerificationScreen();
            }
            // Pantalla temporal — reemplazar con HomeScreen cuando esté listo
            return _HomeTemp(
              nombre: auth.usuario?.nombre ?? 'Usuario',
              negocio: auth.usuario?.negocio ?? '',
            );

          default:
            return const LoginScreen();
        }
      },
    );
  }
}

/// Splash screen mostrado durante la verificación inicial de sesión.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.fondo,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primario),
      ),
    );
  }
}

/// Pantalla de inicio temporal hasta que el Home esté implementado.
/// Eliminar cuando se integre el módulo de Home real.
class _HomeTemp extends StatelessWidget {
  final String nombre;
  final String negocio;

  const _HomeTemp({required this.nombre, required this.negocio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        title:
            const Text('Orden', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.exito),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido, $nombre!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textoOscuro,
              ),
            ),
            if (negocio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(negocio,
                  style: const TextStyle(color: AppColors.textoGris)),
            ],
          ],
        ),
      ),
    );
  }
}

