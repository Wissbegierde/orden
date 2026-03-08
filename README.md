# A la orden, Jefe

## Nombre del Proyecto
**A la orden, Jefe**

## Logotipo
<img width="441" height="345" alt="image" src="https://github.com/user-attachments/assets/54d43c5d-7d05-4843-9731-bd68742b32a3" />


## Eslogan
**"Su negocio, mi trabajo"**
## Integrantes del Equipo

- **Sergio Martínez** — Ideador y clarificador  
- **Daniel Leal** — Desarrollador e implementador  
- **Juan Mena** — Desarrollador  
- **Miguel Bolaño** — Desarrollador  
- **Luis Suárez** — Desarrollador  
## 🎥 Demo del Proyecto

Puedes ver la demostración del funcionamiento de la aplicación en el siguiente enlace:

[Ver video de demostración](https://drive.google.com/file/d/1Q7h3dAdIgh9bbB4leuEUnXF4qVjI_EzX/view?usp=drive_link)
## Actividades Clave

### Planeación del Proyecto
- [ ] Definir el problema que resuelve la aplicación
- [ ] Identificar el público objetivo (microempresas y pequeños negocios)
- [ ] Definir las funcionalidades principales del sistema
- [ ] Organizar el trabajo del equipo usando metodología Scrum

### Diseño del Producto
- [ ] Diseñar la arquitectura del sistema
- [ ] Diseñar la interfaz de usuario de la aplicación
- [ ] Definir la estructura de la base de datos
- [ ] Diseñar la experiencia de uso del control por voz

### Desarrollo del MVP
- [ ] Implementar módulo de ingresos
- [ ] Implementar módulo de gastos
- [ ] Implementar módulo de inventario
- [ ] Integrar reconocimiento de voz en la aplicación
- [ ] Conectar la aplicación con la base de datos

### Pruebas y Mejora
- [ ] Realizar pruebas funcionales del sistema
- [ ] Corregir errores detectados
- [ ] Mejorar la usabilidad de la aplicación

### Lanzamiento
- [ ] Preparar documentación del proyecto
- [ ] Realizar presentación del producto
- [ ] Publicar la primera versión de la aplicación



# 📦 A la Orden Jefe — Documentación del Proyecto

> **Versión:** 1.0.0 | **Plataforma:** Android (Flutter) | **Backend:** Firebase

---

## 1. Introducción

### ¿Qué es?
**A la Orden Jefe** es una aplicación móvil de gestión empresarial diseñada para **microempresas colombianas**. Permite registrar y controlar ingresos, gastos, compras e inventario de forma simple, rápida y —de manera destacada— **por control de voz**.

### Problema que resuelve
Los dueños de micronegocios (tiendas, distribuidoras, etc.) no siempre tienen tiempo para tipear datos manualmente. Esta app permite **dictar la información** al celular mientras se sigue atendiendo al cliente.

---

## 2. Descripción General

### ¿Qué hace?
- Registra ventas (al contado y a crédito)
- Controla gastos y facturas de proveedores
- Registra compras y actualiza inventario automáticamente
- Gestiona el inventario de productos
- Genera reportes por módulo y globales
- Permite **navegar y llenar formularios completamente por voz**

### Dirigida a
Propietarios de microempresas: tiendas de barrio, distribuidoras, pequeños negocios informales.

---

## 3. Tecnologías Utilizadas

| Tecnología | Uso |
|---|---|
| **Flutter 3** + Dart | Framework UI multiplataforma |
| **Firebase Auth** | Autenticación de usuarios |
| **Cloud Firestore** | Base de datos en tiempo real |
| **Provider** | Gestión de estado (patrón ChangeNotifier) |
| **speech_to_text ^7.0** | Reconocimiento de voz |
| **fl_chart ^0.69** | Gráficas en reportes |
| **intl ^0.20** | Formato de fechas y moneda (es_CO) |
| **flutter_svg ^2.0** | Logo en SVG |
| **shared_preferences** | Preferencias locales |

---

## 4. Arquitectura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada, providers globales
├── firebase_options.dart      # Config Firebase generada automáticamente
│
├── models/                    # Entidades de datos (POJOs)
│   ├── income_sale.dart       # Venta / crédito
│   ├── income_payment.dart    # Abono a crédito
│   ├── bill.dart              # Gasto / factura
│   ├── shopping.dart          # Compra a proveedor
│   ├── product.dart           # Producto del inventario
│   └── user_model.dart        # Usuario autenticado
│
├── providers/                 # Lógica de negocio + comunicación con Firestore
│   ├── income_provider.dart
│   ├── bills_provider.dart
│   ├── shopping_provider.dart
│   └── inventory_provider.dart
│
├── services/                  # Servicios externos
│   ├── auth_service.dart      # Login / logout Firebase Auth
│   └── voice_command_service.dart  # Motor de voz: normalización y aliases
│
├── mixins/
│   └── voice_form_mixin.dart  # Lógica de dictado en formularios
│
├── widgets/
│   ├── voice_overlay.dart     # FAB + banner de voz para pantallas de módulo
│   └── module_card.dart       # Tarjeta de módulo en HomeScreen
│
└── screens/
    ├── home_screen.dart        # Pantalla principal con módulos
    ├── auth/                   # Login y registro de cuenta
    ├── income/                 # Módulo Ingresos
    ├── bills/                  # Módulo Gastos
    ├── shopping/               # Módulo Compras
    ├── inventory/              # Módulo Inventario
    └── reports/                # Reportes globales
```

### Patrón arquitectónico
**MVVM simplificado:** `Screen (View)` → `Provider (ViewModel)` → `Firestore (Model)`.  
Los providers extienden `ChangeNotifier` y exponen streams de Firestore directamente a la UI mediante `StreamBuilder`.

---

## 5. Módulos del Sistema

### 🟢 Ingresos (`/screens/income/`)
- Registrar ventas de productos (al contado o a crédito)
- Ver deudas pendientes de clientes
- Registrar abonos a créditos
- Consultar reportes: ventas por período, créditos activos, totales

**Pantallas:** `income_screen`, `register_sale_screen`, `register_payment_screen`, `reports_screen`

---

### 🔴 Gastos (`/screens/bills/`)
- Registrar gastos/facturas con categoría, proveedor, importe y fecha
- Categorías: Servicios, Materia Prima, Arriendo, Nomina, etc.
- Registrar pagos a proveedores
- Ver gastos eliminados (papelera)
- Consultar reportes: gastos por categoría, por período, gráficas

**Pantallas:** `bills_screen`, `register_bill_screen`, `register_payment_screen`, `reports_screen`, `deleted_bills_screen`

---

### 🟡 Compras (`/screens/shopping/`)
- Registrar compras de mercancía a proveedores
- Asociar compra a un producto del inventario (actualiza stock automáticamente)
- Registrar pagos de compras pendientes
- Reportes: compras por período, pagadas vs pendientes

**Pantallas:** `shopping_screen`, `register_purchase_screen`, `register_payment_screen`, `reports_screen`

---

### 🔵 Inventario (`/screens/inventory/`)
- Ver todos los productos con stock actual
- Registrar/editar productos (nombre, precio de venta, costo, stock)
- Alertas de stock bajo y productos próximos a vencer
- Fecha de vencimiento opcional por producto

**Pantallas:** `inventory_screen`, `register_product_screen`

---

### 📊 Reportes (`/screens/reports/`)
- Reporte global con resumen financiero consolidado
- Cada módulo tiene su propio reporte interno
- Gráficas de barras y líneas con `fl_chart`
- Filtros por período: diario, semanal, mensual, anual

---

### 🎤 Control por Voz
Funciona en todos los módulos y formularios. Ver sección 6.

---

## 6. Sistema de Control por Voz

### Arquitectura de voz

```
VoiceCommandService (Singleton)
    ├── normalize(text)           → minúsculas + sin tildes
    ├── matchesAny(text, aliases) → word-boundary regex
    ├── extractNumber(text)       → "tres mil" → "3000"
    └── Listas de aliases:
        ├── listoAliases          → ["listo","siguiente","continuar","ok","dale","siga"...]
        ├── guardarAliases        → ["guardar","registrar","grabar"...]
        ├── volverAliases         → ["volver","regresar","cancelar"...]
        ├── ingresosAliases, gastosAliases, comprasAliases...
        └── registrarVentaAliases, nuevoProductoAliases...
```

### Voz en pantallas de módulo (`VoiceCommandOverlay`)
- Widget que envuelve la pantalla y agrega un **FAB de micrófono**
- Cuando está activo muestra un **banner superior** con el texto reconocido
- Si el comando no es reconocido muestra **"🤔 No entiendo: ..."**
- El callback `onCommand(String) → bool` determina si el comando fue válido

### Voz en formularios (`VoiceFormMixin`)
Mixin que se aplica con `with VoiceFormMixin` al `State` de cada formulario.

**Flujo de dictado:**
```
[Presionas FAB mic] → Escucha campo 1
    → Dices "tres mil" → Campo se llena con "3000"
    → Dices "listo"    → Avanza a Campo 2 (valor conservado)
    → Dices "sí señor" → Campo 2 lleno
    → Dices "siguiente"→ Avanza a Campo 3
    → Dices "guardar"  → Guarda el formulario
[Presionas FAB mic] → Desactiva voz
```

**Reglas clave:**
- Los comandos (`listo`, `guardar`, `volver`) **nunca se escriben en el campo** — se restaura el valor previo
- Funciona con campos opcionales: decir "listo" en un campo vacío simplemente lo salta
- Al llegar al último campo, sigue escuchando para detectar "guardar"
- La escucha se reinicia automáticamente después de cada dictado

---

## 7. Flujo Básico de Uso

```
1. Abrir app → Pantalla de login (Firebase Auth)
2. Home Screen → Ver módulos disponibles
3. Toca o dice "ingresos" / "gastos" / etc. → Abre el módulo
4. Dentro del módulo → Toca "Registrar" o dice el comando
5. En el formulario:
   a) Manual: Toca cada campo y escribe
   b) Voz: Presiona FAB 🎤, dicta campo a campo
6. Dice "guardar" o toca el botón → Guardado en Firestore
7. En la lista del módulo ve el registro nuevo en tiempo real
8. Accede a Reportes → Consulta resúmenes y gráficas
```

---

## 8. Estructura de Datos (Firestore)

### `IncomeSale` — Venta
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID Firestore |
| `productName` | String | Nombre del producto |
| `quantity` | int | Cantidad vendida |
| `totalAmount` | double | Total de la venta |
| `paymentType` | String | efectivo / crédito / transferencia |
| `clientName` | String? | Nombre del cliente (crédito) |
| `pendingAmount` | double? | Saldo pendiente (crédito) |
| `date` | DateTime | Fecha de la venta |

### `Bill` — Gasto
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID Firestore |
| `description` | String | Descripción del gasto |
| `amount` | double | Monto |
| `category` | String | Categoría (servicios, materia prima...) |
| `providerName` | String | Proveedor |
| `paymentType` | String | Forma de pago |
| `paid` | bool | ¿Está pagado? |
| `date` | DateTime | Fecha |

### `Shopping` — Compra
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID Firestore |
| `description` | String | Descripción |
| `amount` | double | Monto |
| `providerName` | String | Proveedor |
| `productId` | String? | Referencia a producto |
| `quantity` | int? | Unidades compradas |
| `paid` | bool | ¿Pagado? |

### `Product` — Producto
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | String | ID Firestore |
| `name` | String | Nombre |
| `price` | double | Precio de venta |
| `costPrice` | double | Precio de costo |
| `quantity` | int | Stock actual |
| `defaultPayment` | String | Método de pago preferido |
| `expiryDate` | DateTime? | Fecha de vencimiento |

---

## 9. Instalación y Ejecución

### Prerrequisitos
- Flutter SDK ≥ 3.10
- Android Studio o VS Code
- Cuenta Firebase con proyecto configurado
- Android SDK (API 21+)

### Pasos

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd orden

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase
# Asegúrate de que google-services.json esté en android/app/

# 4. Ejecutar en dispositivo/emulador
flutter run

# 5. Build para producción
flutter build apk --release
```

### Permisos Android requeridos
En `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 10. Futuras Mejoras

- [ ] **Notificaciones push** — alertas de stock bajo y facturas vencidas
- [ ] **Modo offline** — persistencia local con Hive o SQLite
- [ ] **Exportar a PDF/Excel** — reportes descargables
- [ ] **Multi-usuario / roles** — empleados con permisos limitados
- [ ] **Dashboard global** — vista consolidada de todos los módulos
- [ ] **Backup automático** — exportar datos a Google Drive
- [ ] **Soporte iOS** — actualmente solo Android
- [ ] **Voz proactiva** — la app habla de vuelta al usuario (text-to-speech)
- [ ] **Reconocimiento de imágenes** — escanear facturas con la cámara

---

*Documentación generada: Marzo 2026*
