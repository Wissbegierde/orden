// lib/models/voice_command.dart
class VoiceCommand {
  final VoiceCommandType type;
  final Map<String, dynamic> data;
  final String originalText;

  VoiceCommand({
    required this.type,
    required this.data,
    required this.originalText,
  });
}

enum VoiceCommandType {
  // Navegación
  navigate,
  back,

  // Gastos
  registerBill,

  // Ingresos
  registerIncome,

  // Inventario
  addProduct,

  // Confirmaciones
  confirm,
  cancel,

  // Consultas
  viewReport,

  // Desconocido
  unknown,
}
