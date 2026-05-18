# App-Frontend-Wask

Frontend movil de WAS-K construido en Flutter.

## Configuracion de entorno

La app usa `--dart-define` para configurar la URL del backend y habilitar mocks.
Los valores se leen desde `AppConfig` en [lib/core/config/app_config.dart](lib/core/config/app_config.dart).

### Comandos comunes

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=ENABLE_MOCKS=false
```

iOS simulator:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=ENABLE_MOCKS=false
```

Produccion:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://mi-backend.com/api/v1 --dart-define=ENABLE_MOCKS=false
```

## Dependencias

```bash
flutter pub get
```
