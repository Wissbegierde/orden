import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _negocioCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _registrar() async {
    if (_nombreCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty || _negocioCtrl.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos obligatorios');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.registrar(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        negocio: _negocioCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Error al registrar. Intenta con otro correo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _campo(_nombreCtrl, 'Nombre completo *', Icons.person_outline),
            const SizedBox(height: 14),
            _campo(_negocioCtrl, 'Nombre del negocio *', Icons.store_outlined),
            const SizedBox(height: 14),
            _campo(_emailCtrl, 'Correo electrónico *', Icons.email_outlined,
                tipo: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _campo(_telefonoCtrl, 'Teléfono (opcional)', Icons.phone_outlined,
                tipo: TextInputType.phone),
            const SizedBox(height: 14),
            _campo(_passCtrl, 'Contraseña *', Icons.lock_outline, oculto: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _registrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear cuenta',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType tipo = TextInputType.text, bool oculto = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      obscureText: oculto,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}