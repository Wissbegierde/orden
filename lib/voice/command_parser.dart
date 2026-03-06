// lib/voice/command_parser.dart
import '../models/voice_command.dart';

class CommandParser {
  VoiceCommand parse(String text) {
    final lowerText = text.toLowerCase().trim();

    // NAVEGACIÓN
    if (_containsAny(lowerText, ['ir a gastos', 'gastos', 'ir gastos'])) {
      return VoiceCommand(
        type: VoiceCommandType.navigate,
        data: {'screen': 'bills'},
        originalText: text,
      );
    }

    if (_containsAny(lowerText, ['ir a ingresos', 'ingresos'])) {
      return VoiceCommand(
        type: VoiceCommandType.navigate,
        data: {'screen': 'income'},
        originalText: text,
      );
    }

    if (_containsAny(lowerText, ['ir a inventario', 'inventario'])) {
      return VoiceCommand(
        type: VoiceCommandType.navigate,
        data: {'screen': 'inventory'},
        originalText: text,
      );
    }

    if (_containsAny(lowerText, ['volver', 'atrás', 'regresar', 'menú'])) {
      return VoiceCommand(
        type: VoiceCommandType.back,
        data: {},
        originalText: text,
      );
    }

    // GASTOS
    if (_containsAny(lowerText, [
      'registrar gasto',
      'anotar gasto',
      'gasto de',
    ])) {
      final amount = _extractAmount(lowerText);
      final category = _extractCategory(lowerText);

      return VoiceCommand(
        type: VoiceCommandType.registerBill,
        data: {'amount': amount, 'category': category},
        originalText: text,
      );
    }

    // INGRESOS
    if (_containsAny(lowerText, [
      'registrar ingreso',
      'anotar ingreso',
      'ingreso de',
    ])) {
      final amount = _extractAmount(lowerText);

      return VoiceCommand(
        type: VoiceCommandType.registerIncome,
        data: {'amount': amount},
        originalText: text,
      );
    }

    // CONFIRMACIONES
    if (_containsAny(lowerText, [
      'sí',
      'si',
      'confirmar',
      'aceptar',
      'ok',
      'dale',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.confirm,
        data: {},
        originalText: text,
      );
    }

    if (_containsAny(lowerText, ['no', 'cancelar', 'negativo'])) {
      return VoiceCommand(
        type: VoiceCommandType.cancel,
        data: {},
        originalText: text,
      );
    }

    // DESCONOCIDO
    return VoiceCommand(
      type: VoiceCommandType.unknown,
      data: {},
      originalText: text,
    );
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any((phrase) => text.contains(phrase));
  }

  double? _extractAmount(String text) {
    // Buscar números
    final RegExp numberRegex = RegExp(r'\d+');
    final match = numberRegex.firstMatch(text);

    if (match != null) {
      double amount = double.parse(match.group(0)!);

      // Si dice "mil", multiplicar por 1000
      if (text.contains('mil')) {
        amount *= 1000;
      }

      return amount;
    }

    return null;
  }

  String? _extractCategory(String text) {
    final categories = {
      'transporte': ['transporte', 'gasolina', 'combustible', 'taxi'],
      'servicios': ['servicios', 'luz', 'agua', 'internet'],
      'salarios': ['salarios', 'sueldo', 'nómina', 'pago empleado'],
      'arriendo': ['arriendo', 'alquiler', 'renta'],
    };

    for (var entry in categories.entries) {
      if (entry.value.any((word) => text.contains(word))) {
        return entry.key;
      }
    }

    return null;
  }
}
