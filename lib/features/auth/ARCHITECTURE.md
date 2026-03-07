# Módulo Auth v2 — Arquitectura y Mejoras

## Resumen

Este módulo es una reconstrucción completa del sistema de autenticación de **orden**,
aplicando Clean Architecture estricta, correcciones de seguridad críticas y optimizaciones
de rendimiento identificadas en el análisis técnico previo.

---

## Estructura de carpetas

```
auth/
├── domain/                          # Capa más interna — sin dependencias externas
│   ├── entities/
│   │   └── user.dart                # Entidad de usuario (Dart puro, sin Firebase)
│   ├── value_objects/
│   │   ├── email_address.dart       # Email validado y normalizado
│   │   └── password.dart            # Contraseña con política de seguridad
│   ├── repositories/
│   │   └── auth_repository.dart     # Contrato abstracto (Stream<User?>)
│   └── exceptions/
│       └── auth_exception.dart      # Excepciones de dominio tipadas
│
├── data/                            # Capa de infraestructura
│   ├── dtos/
│   │   └── user_dto.dart            # Serialización Firestore (Timestamp aquí, NO en domain)
│   └── repositories/
│       └── auth_repository_impl.dart  # Implementación con Firebase Auth + Firestore
│
└── presentation/                    # Capa de UI
    ├── providers/
    │   └── auth_provider.dart       # Estado global (ChangeNotifier + Stream<User?>)
    ├── screens/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── forgot_password_screen.dart
    │   └── email_verification_screen.dart
    └── widgets/
        ├── auth_header.dart
        ├── error_banner.dart
        ├── password_strength_indicator.dart
        └── section_label.dart
```

---

## Regla de dependencias

```
presentation  →  domain  ←  data
```

- **domain** no importa nada externo.
- **data** depende de domain (implementa sus contratos) y de Firebase/Firestore.
- **presentation** depende de domain (usa sus tipos) pero nunca de data directamente.
- La inyección de `AuthRepositoryImpl` en `AuthProvider` ocurre en `main.dart`.

---

## Mejoras aplicadas (referencia al análisis técnico)

### 🔴 Críticas (resueltas)

| # | Problema original | Solución aplicada |
|---|---|---|
| 1 | `password.trim()` alteraba contraseñas silenciosamente | `Password` value object **nunca aplica trim()**. El valor se usa exacto. |
| 2 | `user-not-found` expuesto como tipo de error diferente | Mapeado al mismo `credencialesInvalidas` que `wrong-password`. Sin enumeración de usuarios. |
| 3 | `Timestamp` de Firestore dentro de `UserModel` (domain) | Movido a `UserDto` en la capa data. `User` usa solo `DateTime` Dart. |

### 🟠 Altas (resueltas)

| # | Problema original | Solución aplicada |
|---|---|---|
| 4 | Mínimo de contraseña de 6 caracteres | `Password` exige mínimo **8 caracteres**. `PasswordStrengthIndicator` actualizado. |
| 5 | `AuthProvider` importaba `AuthRepositoryImpl` directamente | Constructor requiere `AuthRepository` explícito. **DI estricta.** |
| 6 | Sin `onError` en el stream de auth | `_escucharCambiosDeAuth()` incluye `onError` handler. App no crashea ante errores de Firebase. |
| 7 | `actualizarPerfil()` envolvía `AuthException` como `desconocido` | Añadido `if (e is AuthException) rethrow` antes del catch genérico. |

### 🟡 Medias (resueltas)

| # | Problema original | Solución aplicada |
|---|---|---|
| 8 | Polling fijo cada 5 s sin límite | **Backoff exponencial**: 5 s → 10 s → 20 s → 30 s. Límite de 20 intentos (~7 min). |
| 9 | `Stream<bool>` requería lectura extra a Firestore | Cambiado a `Stream<User?>` con `asyncMap`. El provider recibe el modelo completo. |
| 10 | `withOpacity()` deprecado en Flutter 3.x | Reemplazado por `withValues(alpha:)` en todos los widgets. |

### 🟢 Bajas (resueltas)

| # | Problema original | Solución aplicada |
|---|---|---|
| 11 | Sin validación defensiva en repositorio | `AuthRepositoryImpl` valida `nombre` y `negocio` antes de llamar a Firebase. |
| 12 | `debugPrint` en producción sin control | Centralizado en `_log()` que solo actúa cuando `kDebugMode == true`. |
| 13 | `emailVerificado` almacenado en Firestore | **Eliminado de Firestore.** Se lee siempre de `FirebaseUser.emailVerified`. |
| 14 | `correoVerificacionEnviado` no se reseteaba en logout | Reseteado en `_handleAuthChange(null)` y en `logout()`. |
| 15 | `login()` hacía update + get (2 round-trips) | `login()` hace auth + update fire-and-forget. Stream propaga el estado. |

---

## Inyección de dependencias (ejemplo de integración)

```dart
// main.dart
ChangeNotifierProvider(
  create: (_) => AuthProvider(
    repo: AuthRepositoryImpl(
      // Opcional: inyectar instancias mock en tests
      auth: FirebaseAuth.instance,
      db: FirebaseFirestore.instance,
    ),
  ),
)
```

En tests:
```dart
final mockRepo = MockAuthRepository();
final provider = AuthProvider(repo: mockRepo);
// No se necesita Firebase en el entorno de test
```

---

## Notas de seguridad (OWASP ASVS)

- **ASVS 2.1.1** — Mínimo 8 caracteres en contraseñas.
- **ASVS 2.2.1** — No diferenciar entre "usuario no existe" y "contraseña incorrecta".
- **ASVS 2.5.6** — Verificación de correo requerida (gestionada por `EmailVerificationScreen`).
- **Datos PII** — `_log()` nunca imprime contraseñas, tokens ni UIDs en producción.
- **Segunda fuente de verdad** — `emailVerificado` se lee siempre de Firebase Auth, nunca de Firestore.

---

## Compatibilidad

- Flutter 3.x con null-safety habilitado
- Firebase Auth SDK ≥ 5.x
- Cloud Firestore SDK ≥ 5.x
- Provider ≥ 6.x
- Dart SDK ≥ 3.0
