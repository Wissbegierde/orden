import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTRO
  Future<UserModel?> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      uid: cred.user!.uid,
      nombre: nombre,
      email: email,
      telefono: telefono,
      negocio: '',
    );

    // Guardar en Firestore
    await _db.collection('usuarios').doc(user.uid).set({
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Guardar datos extra localmente (Caché rápido)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('telefono', telefono);

    return user;
  }

  // LOGIN
  Future<User?> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // OBTENER DATOS LOCALES
  Future<Map<String, String>> getDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombre': prefs.getString('nombre') ?? '',
      'telefono': prefs.getString('telefono') ?? '',
    };
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    await _auth.signOut();
  }
}
