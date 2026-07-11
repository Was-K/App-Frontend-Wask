# CLAUDE.md — App-Frontend-Wask (Móvil / Flutter)

> Contexto para asistentes de IA. App móvil del **CLIENTE final** (`CUSTOMER`).
> Consume `API-Wask` (ver su `CLAUDE.md` para el contrato de API completo).

## Qué es

App Flutter donde el **cliente** navega tiendas y productos (licores, etc.), arma un carrito,
hace pedidos y hace seguimiento de entregas. Las tiendas y productos que ve provienen de lo que
los proveedores publican en la web `Wask-Business-App`. Rol principal: `CUSTOMER`.

## Stack

- Flutter (Dart SDK ^3.5.3), Material, tema oscuro (`WaskTheme.darkTheme`)
- Estado: **provider** (`ChangeNotifierProvider`)
- Red: paquete `http`
- `shared_preferences` (tokens), `google_maps_flutter` + `location` (mapa/tracking)
- `firebase_auth` + `cloud_firestore` (presentes en deps; verificar uso real)

## Comandos

```bash
flutter pub get
flutter run
# Config vía --dart-define:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Configuración de red

- **`lib/core/config/app_config.dart`**: `API_BASE_URL` (default `http://10.0.2.2:3000/api/v1`
  — `10.0.2.2` = localhost del host desde el emulador Android). `ENABLE_MOCKS`.
- **`lib/core/network/api_client.dart`**: cliente `http` tipado con `parser`.
  - Agrega `Authorization: Bearer` automáticamente.
  - En 401 hace **un** refresh (`/auth/refresh-token`) y reintenta; si falla, limpia tokens y lanza `ApiException`.
  - Desenvuelve `{ success, data }` y pasa `data` al `parser`. Timeout 20s.
- **`lib/core/network/token_storage.dart`**: access/refresh en `shared_preferences`.

## Estructura

```
lib/
├── main.dart               # MultiProvider (AppState, Cart, Tracking) + rutas
├── core/
│   ├── config/app_config.dart
│   ├── network/            # api_client, api_exception, token_storage
│   ├── navigation/wask_routes.dart
│   └── theme/wask_theme.dart
└── features/               # cada feature: data/ (services), screens/, providers/, models/
    ├── auth/    home/    shop/     products/  suppliers/  cart/
    ├── checkout/ orders/ tracking/ logistics/ search/     address/
    ├── account/ dashboard/ shared/ (models: app_models.dart)
```

Patrón por feature: `data/*_service.dart` (llama `ApiClient`) + `providers/` (estado) + `screens/` (UI).

## Contrato de API (resumen — ver CLAUDE.md del backend)

Base: `/api/v1`. Envelope `{ success, data, timestamp }`. El backend usa `forbidNonWhitelisted`:
**enviar SOLO los campos del DTO** o responde 400.

Endpoints correctos: `/auth/login`, `/auth/refresh-token`, `/auth/logout`, `/auth/validate-session`,
`/users/me`, `/products` (GET, CUSTOMER ve APPROVED+ACTIVE), `/orders` (POST/GET), `/orders/:id/status`,
`/logistics/shipments*`.

## Estado de conexión (corregido 2026-07)

1. ✅ **Registro**: `auth_service.register()` llama `POST /auth/register-customer` con
   `{firstName, lastName, email, password, phone?}`. La pantalla ya no pide "rol" (siempre CUSTOMER).
2. ✅ **Tiendas**: `suppliers_service.dart` consume `GET /business/shops` y `GET /business/shops/:id`
   (solo lectura). `Supplier.fromJson` es tolerante a la forma `Business` (`companyName`, `operationalStatus`).
3. ✅ **Productos**: `products_service` es solo lectura (`getProducts`, `getProduct`) y filtra por `businessId`.
   `Product.fromJson` puebla su `supplierId` interno desde el `businessId` del backend.
4. ✅ **Pedidos**: `orders_service.createOrder` envía solo `businessId` (la tienda), `items`, `notes`,
   `deliveryAddress`. En checkout el `businessId` sale de los items del carrito, no de `currentUser.companyId`.

### Convención interna importante
- En el móvil, el campo `supplierId` (Product, CartItem, checkout) representa el **`businessId`** de la tienda
  del backend. Es solo nomenclatura local; al hablar con la API siempre se envía/lee como `businessId`.

### Pendiente menor
- El módulo `suppliers`/modelo `Supplier` conserva el nombre por compatibilidad; podría renombrarse a `shops`/`Business`.

## Convenciones

- Toda llamada de red pasa por `ApiClient` con un `parser` explícito (no `jsonDecode` suelto en screens).
- Estado con `provider`. Servicios en `features/<x>/data/`.
- Al cambiar un endpoint, verificar el path y los campos del DTO contra el `CLAUDE.md` del backend.
