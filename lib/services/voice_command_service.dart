import 'package:speech_to_text/speech_to_text.dart';

/// Servicio central de voz — Singleton.
/// Encapsula [SpeechToText], normalización de texto y tabla de aliases
/// para español colombiano.
class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final SpeechToText speech = SpeechToText();
  bool _initialized = false;
  bool get isAvailable => _initialized;

  /// Inicializa el reconocimiento. Seguro de llamar múltiples veces.
  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  // ───────────────────── NORMALIZACIÓN ─────────────────────

  /// Quita tildes, pasa a minúsculas, limpia espacios.
  static String normalize(String text) {
    var s = text.toLowerCase().trim();
    s = s.replaceAll('á', 'a');
    s = s.replaceAll('é', 'e');
    s = s.replaceAll('í', 'i');
    s = s.replaceAll('ó', 'o');
    s = s.replaceAll('ú', 'u');
    s = s.replaceAll('ñ', 'n');
    s = s.replaceAll('ü', 'u');
    // Limpiar espacios múltiples
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// Retorna true si [text] contiene alguno de los [aliases] como palabra completa.
  /// Usa word-boundary para evitar que "inventario" machee con "venta".
  static bool matchesAny(String text, List<String> aliases) {
    final norm = normalize(text);
    for (final alias in aliases) {
      final normAlias = normalize(alias);
      if (norm == normAlias) return true;
      // Usar word boundary (\b) para que solo machee palabras completas
      final pattern = RegExp(r'\b' + RegExp.escape(normAlias) + r'\b');
      if (pattern.hasMatch(norm)) return true;
    }
    return false;
  }

  // ───────────────────── ALIASES POR COMANDO ─────────────────────

  // ─── Navegación desde HomeScreen ───
  static const ingresosAliases = [
    'ingresos', 'ingreso', 'ventas', 'venta', 'entradas', 'plata',
    'ir a ingresos', 'abrir ingresos', 'entrar a ingresos',
    'ir a ventas', 'abrir ventas', 'entrar a ventas',
  ];

  static const gastosAliases = [
    'gastos', 'gasto', 'facturas', 'factura', 'cuentas',
    'ir a gastos', 'abrir gastos', 'entrar a gastos',
  ];

  static const comprasAliases = [
    'compras', 'compra', 'pedidos', 'mercancia', 'mercancía',
    'ir a compras', 'abrir compras', 'entrar a compras',
  ];

  static const inventarioAliases = [
    'inventario', 'productos', 'stock', 'bodega',
    'ir a inventario', 'abrir inventario', 'entrar a inventario',
    'ir a productos', 'abrir productos', 'entrar a productos',
  ];

  static const reportesAliases = [
    'reportes', 'reporte', 'informe', 'informes',
    'estadisticas', 'estadísticas',
    'ir a reportes', 'abrir reportes', 'entrar a reportes',
  ];

  // ─── Acciones dentro de módulos ───
  static const registrarVentaAliases = [
    'registrar venta', 'nueva venta', 'agregar venta', 'meter venta',
    'hacer venta', 'crear venta',
  ];

  static const registrarAbonoAliases = [
    'registrar abono', 'nuevo abono', 'agregar abono', 'meter abono',
    'hacer abono', 'abono',
  ];

  static const registrarGastoAliases = [
    'registrar gasto', 'nuevo gasto', 'agregar gasto', 'meter gasto',
    'hacer gasto', 'crear gasto',
  ];

  static const registrarCompraAliases = [
    'registrar compra', 'nueva compra', 'agregar compra', 'meter compra',
    'hacer compra', 'crear compra',
  ];

  static const nuevoProductoAliases = [
    'nuevo producto', 'agregar producto', 'añadir producto', 'meter producto',
    'crear producto', 'registrar producto',
  ];

  static const pagoProveedorAliases = [
    'pago proveedor', 'pagar proveedor', 'pago a proveedor',
    'abono proveedor', 'pagar credito', 'pagar crédito',
  ];

  static const reportesModuloAliases = [
    'reportes', 'reporte', 'ver reportes', 'informe', 'informes',
  ];

  // ─── Comandos de formulario ───
  static const listoAliases = [
    'listo', 'siguiente', 'continuar', 'ok', 'dale', 'ya',
    'siga', 'listos', 'vale', 'bueno', 'okey',
  ];

  static const guardarAliases = [
    'guardar', 'registrar', 'grabar', 'salvar',
    'guardar venta', 'guardar gasto', 'guardar compra', 'guardar producto',
    'guardar abono', 'registrar venta', 'registrar gasto',
    'registrar compra', 'registrar producto', 'registrar abono',
  ];

  static const volverAliases = [
    'volver', 'regresar', 'atras', 'atrás', 'cancelar', 'salir',
    'devolver', 'ir atras', 'ir atrás',
  ];

  // ───────────────────── CONVERSIÓN DE NÚMEROS ─────────────────────

  /// Convierte texto hablado a número. Ej: "dos mil" → "2000", "quince" → "15"
  static String extractNumber(String text) {
    final norm = normalize(text);

    // Mapa de palabras a números
    const Map<String, int> wordToNum = {
      'cero': 0, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
      'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9,
      'diez': 10, 'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14,
      'quince': 15, 'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18,
      'diecinueve': 19, 'veinte': 20, 'veintiuno': 21, 'veintidos': 22,
      'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25,
      'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
      'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60,
      'setenta': 70, 'ochenta': 80, 'noventa': 90,
      'cien': 100, 'ciento': 100, 'doscientos': 200, 'trescientos': 300,
      'cuatrocientos': 400, 'quinientos': 500, 'seiscientos': 600,
      'setecientos': 700, 'ochocientos': 800, 'novecientos': 900,
      'mil': 1000, 'millon': 1000000,
    };

    // Si ya es un número directo, retornarlo
    final directNumber = norm.replaceAll(RegExp(r'[^0-9]'), '');
    if (directNumber.isNotEmpty && directNumber.length == norm.replaceAll(' ', '').length) {
      return directNumber;
    }

    // Intento simple: buscar coincidencia directa
    if (wordToNum.containsKey(norm)) {
      return wordToNum[norm]!.toString();
    }

    // Para "X mil Y" patterns
    final parts = norm.split(' ');
    int result = 0;
    int current = 0;

    for (final part in parts) {
      if (part == 'y') continue;

      if (wordToNum.containsKey(part)) {
        final val = wordToNum[part]!;
        if (val == 1000) {
          current = current == 0 ? 1000 : current * 1000;
          result += current;
          current = 0;
        } else if (val == 1000000) {
          current = current == 0 ? 1000000 : current * 1000000;
          result += current;
          current = 0;
        } else {
          current += val;
        }
      } else {
        // Puede ser un número directo parcial
        final parsed = int.tryParse(part);
        if (parsed != null) current += parsed;
      }
    }
    result += current;

    return result > 0 ? result.toString() : text;
  }
}
