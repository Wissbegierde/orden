# Módulo de Gastos - Documentación Técnica

## Descripción General
El módulo de gastos permite registrar, gestionar y reportar los gastos de la microempresa. Incluye:
- Registro diario de gastos (efectivo, crédito, transferencia, tarjeta)
- Registro de pagos de gastos
- Reportes diario, semanal y mensual

## Estructura de Archivos Creados

### 1. Modelos
**Ubicación:** `/lib/models/bill.dart`

#### Clases:
- **`Bill`**: Representa un gasto
  - Campos: id, description, amount, paymentType, category, date, paid, providerName, notes
  - Métodos: `toFirestore()`, `fromFirestore()`

- **`BillPayment`**: Representa un pago de gasto
  - Campos: id, billId, amount, date, notes
  - Métodos: `toFirestore()`, `fromFirestore()`

#### Enumeraciones:
- **`PaymentType`**: efectivo, nequi, transferencia, tarjeta
  - Extensión `PaymentTypeExtension` con: `label`, `fromString()`

- **`BillCategory`**: arriendo, servicios, salarios, utiles, otros
  - Extensión `BillCategoryExtension` con: `label`, `fromString()`

### 2. Provider (State Management)
**Ubicación:** `/lib/providers/bills_provider.dart`

#### Clase `BillsProvider` (extends ChangeNotifier)

**Métodos de Gastos:**
- `billsStream()` - Stream de todos los gastos
- `billsForDay(DateTime)` - Gastos de un día específico
- `billsByCategory(BillCategory)` - Gastos por categoría
- `unpaidBills()` - Gastos no pagados
- `addBill(Bill)` - Crear nuevo gasto
- `updateBill(String, Bill)` - Actualizar gasto
- `deleteBill(String)` - Eliminar gasto

**Métodos de Pagos:**
- `paymentsStream()` - Stream de todos los pagos
- `paymentsForBill(String)` - Pagos de un gasto específico
- `addPayment(BillPayment)` - Registrar pago

**Método de Reportes:**
- `fetchBillsForRange(DateTime, DateTime)` - Gastos en rango de fechas
- `fetchPaymentsForRange(DateTime, DateTime)` - Pagos en rango de fechas
- `getTotalBillsForRange(DateTime, DateTime)` - Total de gastos
- `getTotalPaymentsForRange(DateTime, DateTime)` - Total de pagos

### 3. Pantallas
**Ubicación:** `/lib/screens/bills/`

#### a) `bills_screen.dart`
Pantalla principal del módulo de gastos
- Resumen diario de gastos
- Botones para: Registrar Gasto, Registrar Pago
- Lista de gastos recientes
- Botón para ver reportes

**Widgets:**
- `BillsScreen` (main)
- `_ActionButton` - Botones de acción
- `_BillCard` - Tarjeta de gasto individual

#### b) `register_bill_screen.dart`
Pantalla para registrar un nuevo gasto
- Formulario con:
  - Selector de categoría (chips)
  - Descripción (con reconocimiento de voz)
  - Monto (con reconocimiento de voz)
  - Proveedor (opcional, con reconocimiento de voz)
  - Forma de pago (dropdown)
  - Selector de fecha
  - Checkbox para marcar como pagado
  - Notas (opcional, con reconocimiento de voz)
- Validación de datos
- Integración con Firebase

**Características:**
- Reconocimiento de voz Speech-to-Text
- Validación de formulario
- Guardado en Firestore

#### c) `register_payment_screen.dart`
Pantalla para registrar un pago de gasto
- Selector de gasto no pagado
- Visualización del detalle del gasto seleccionado
- Formulario con:
  - Monto del pago (con reconocimiento de voz)
  - Fecha del pago
  - Notas (opcional, con reconocimiento de voz)
- Validación de datos

**Características:**
- Stream de gastos no pagados
- Reconocimiento de voz
- Validación del monto contra el gasto total

#### d) `reports_screen.dart`
Pantalla de reportes de gastos
- Tabs para: Diario, Semanal, Mensual
- Tarjetas de resumen:
  - Total Gastos
  - Total Pagado
  - Pendiente de Pago
- Gráfico de barras por período y categoría
- Desglose por categoría con porcentajes

**Widgets:**
- `BillsReportsScreen` (main)
- `_SummaryCard` - Tarjeta de resumen
- `_CategoryBreakdown` - Breakdown por categoría

## Flujo de Datos

### 1. Registrar Gasto
```
RegisterBillScreen 
    → validación 
    → BillsProvider.addBill() 
    → Firestore (collection: 'gastos')
    → StreamBuilder en BillsScreen se actualiza
```

### 2. Registrar Pago
```
RegisterBillPaymentScreen 
    → selecciona gasto de unpaidBills
    → validación 
    → BillsProvider.addPayment() 
    → Firestore (collection: 'pagos_gastos')
    → StreamBuilder se actualiza
```

### 3. Ver Reportes
```
BillsReportsScreen 
    → selecciona período (daily/weekly/monthly)
    → BillsProvider.fetchBillsForRange()
    → procesa datos por categoría
    → genera gráfico
    → calcula porcentajes
```

## Integración en main.dart

Se añadió el `BillsProvider` al `MultiProvider`:
```dart
providers: [
  ChangeNotifierProvider(create: (_) => IncomeProvider()),
  ChangeNotifierProvider(create: (_) => BillsProvider()),  // Nuevo
]
```

## Integración en home_screen.dart

Se habilitó el módulo GASTOS:
```dart
ModuleCard(
  icon: Icons.trending_down_rounded,
  label: 'GASTOS',
  color: const Color(0xFFEF4444),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BillsScreen()),
  ),
),
```

## Colores del Módulo

| Elemento | Color | Hex |
|----------|-------|-----|
| Principal | Rojo | #EF4444 |
| Pagos | Morado | #8B5CF6 |
| Arriendo | Azul | #3B82F6 |
| Servicios | Morado | #8B5CF6 |
| Salarios | Verde | #10B981 |
| Útiles | Ámbar | #F59E0B |
| Otros | Gris | #6B7280 |

## Colecciones en Firestore

### 1. `gastos`
```json
{
  "description": "string",
  "amount": "number",
  "paymentType": "string (efectivo|nequi|transferencia|tarjeta)",
  "category": "string (arriendo|servicios|salarios|utiles|otros)",
  "date": "timestamp",
  "paid": "boolean",
  "providerName": "string (opcional)",
  "notes": "string (opcional)"
}
```

### 2. `pagos_gastos`
```json
{
  "billId": "string (referencia a documento en gastos)",
  "amount": "number",
  "date": "timestamp",
  "notes": "string (opcional)"
}
```

## Características Especiales

### 1. Reconocimiento de Voz
- Implementado con `speech_to_text` package
- Disponible en campos de texto principales
- Botón micrófono en each input

### 2. Validación
- Campos requeridos validados
- Monto debe ser numérico
- Gasto debe estar seleccionado para pago

### 3. Transacciones
- Uso de transacciones en Firestore
- Sincronización automática con actualizaciones

## Próximas Implementaciones

- Editar gastos registrados
- Eliminar gastos
- Filtros avanzados por fecha rango
- Exportar reportes a PDF
- Alertas de gastos recurrentes
- Categorías personalizadas

## Testing Recomendado

1. Registrar gastos con diferentes categorías y formas de pago
2. Verificar que aparecen en tiempo real en la lista
3. Registrar pagos y validar estado de "pagado"
4. Generar reportes para diferentes períodos
5. Verificar corrección de cálculos en reportes
6. Probar reconocimiento de voz en todos los campos
7. Validar manejo de errores en Firestore
