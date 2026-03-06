// lib/voice/voice_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_command.dart';
import '../providers/bills_provider.dart';
import 'command_parser.dart';
import 'voice_service.dart';

class VoiceController {
  final BuildContext context;
  final CommandParser parser = CommandParser();
  final VoiceService voiceService;

  // Estado de conversación
  VoiceCommandType? _waitingFor;
  Map<String, dynamic> _tempData = {};

  VoiceController({required this.context, required this.voiceService});

  Future<void> processCommand(String text) async {
    final command = parser.parse(text);

    debugPrint('Comando recibido: ${command.type}');
    debugPrint('Datos: ${command.data}');

    // Si estamos esperando confirmación
    if (_waitingFor != null) {
      await _handleConfirmation(command);
      return;
    }

    // Procesar comandos nuevos
    switch (command.type) {
      case VoiceCommandType.navigate:
        await _handleNavigation(command);
        break;

      case VoiceCommandType.registerBill:
        await _handleRegisterBill(command);
        break;

      case VoiceCommandType.registerIncome:
        await _handleRegisterIncome(command);
        break;

      case VoiceCommandType.back:
        Navigator.pop(context);
        await voiceService.speak('Volviendo');
        break;

      case VoiceCommandType.unknown:
        await voiceService.speak('No entendí el comando. Intenta de nuevo.');
        break;

      default:
        break;
    }
  }

  Future<void> _handleNavigation(VoiceCommand command) async {
    final screen = command.data['screen'];

    switch (screen) {
      case 'bills':
        await voiceService.speak('Abriendo gastos');
        Navigator.pushNamed(context, '/bills');
        break;

      case 'income':
        await voiceService.speak('Abriendo ingresos');
        Navigator.pushNamed(context, '/income');
        break;

      case 'inventory':
        await voiceService.speak('Abriendo inventario');
        Navigator.pushNamed(context, '/inventory');
        break;
    }
  }

  Future<void> _handleRegisterBill(VoiceCommand command) async {
    final amount = command.data['amount'];
    final category = command.data['category'];

    if (amount == null) {
      await voiceService.speak('¿Cuál es el monto del gasto?');
      _waitingFor = VoiceCommandType.registerBill;
      return;
    }

    // Guardar datos temporales
    _tempData = {'amount': amount, 'category': category ?? 'otros'};

    // Pedir confirmación
    final amountText = amount.toStringAsFixed(0);
    await voiceService.speak(
      'Registrar gasto de $amountText pesos en ${category ?? "otros"}. ¿Confirmar?',
    );

    _waitingFor = VoiceCommandType.confirm;
  }

  Future<void> _handleRegisterIncome(VoiceCommand command) async {
    final amount = command.data['amount'];

    if (amount == null) {
      await voiceService.speak('¿Cuál es el monto del ingreso?');
      return;
    }

    _tempData = {'amount': amount};

    final amountText = amount.toStringAsFixed(0);
    await voiceService.speak(
      'Registrar ingreso de $amountText pesos. ¿Confirmar?',
    );

    _waitingFor = VoiceCommandType.confirm;
  }

  Future<void> _handleConfirmation(VoiceCommand command) async {
    if (command.type == VoiceCommandType.confirm) {
      // Ejecutar la acción guardada
      if (_waitingFor == VoiceCommandType.confirm) {
        await _executeAction();
      }
    } else if (command.type == VoiceCommandType.cancel) {
      await voiceService.speak('Cancelado');
      _resetState();
    }
  }

  Future<void> _executeAction() async {
    // Aquí conectas con tus providers
    if (_tempData.containsKey('amount')) {
      final amount = _tempData['amount'] as double;

      // Ejemplo: Registrar gasto
      // await context.read<BillsProvider>().addBill(...);

      await voiceService.speak('Registrado exitosamente');
    }

    _resetState();
  }

  void _resetState() {
    _waitingFor = null;
    _tempData = {};
  }
}
