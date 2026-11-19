<!-- impeccable:product-schema 1 -->
# Product

## Platform

adaptive

## Users

Adult Peruvian consumers (+18) in Lima Metropolitana (Miraflores, San Isidro, Lince, Surco, Barranco, Jesus Maria, Pueblo Libre, Magdalena, San Borja, San Miguel) ordering cold beers, pisco, spirits, wines, ice, and mixers during late afternoon, evening, and nocturnal gatherings ("previas") or home delivery moments.

## Product Purpose

Deliver chilled beverages and liquor from verified neighborhood partner stores ("Licorerias Aliadas") in Lima to the customer's exact door in under 30 minutes, covering store and catalog discovery, live search, Peruvian address precision, native local payment methods (Yape, Plin, cash on delivery, POS card), 10-order loyalty rewards, and live OpenStreetMap courier tracking.

## Positioning

Nocturnal Peruvian beverage delivery ("Delivery en Lima en menos de 30 min o es gratis"): verified local liquor stores with real-time branch stock visibility, chilled-ready indicators, native Yape and Plin checkout, and a transparent 10-order loyalty stamp card unlocking a free delivery.

## Operating Context

- Predominantly low-light, evening, and nighttime mobile usage alongside desktop/mobile web access on Flutter Web (`:8080`) and native iOS/Android builds.
- Strict +18 age verification gate prior to sign-in and account registration.
- Consumes `API-Wask` (`/api/v1`) with strict NestJS `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`) and JWT bearer refresh flow.
- Map tracking renders real OpenStreetMap slippy tiles centered on Lima (`-12.104, -77.033`) without external proprietary Google Maps API key failure modes.

## Capabilities and Constraints

- **Catalog & Partner Stores**: Category filtering (`Todo`, `Cerveza`, `Pisco`, `Whisky`, `Vino`, `Ron`, `Hielo`), real backend product photography (`/uploads/*.png`), per-product stock and warehouse availability badges, and clickable partner store catalogs.
- **Visual Search**: Debounced server queries (`GET /products?q=...`) paired with instant local catalog filtering and trending Peruvian liquor search chips (`Pilsen`, `Cristal`, `Cusquena`, `Pisco`, `Whisky`, `Hielo`).
- **Loyalty Program**: Tracks delivered orders (`GET /orders/loyalty`, `POST /orders/loyalty/simulate`); every 10 delivered orders unlocks 1 free delivery, and subtotals >= S/ 80.00 automatically receive free delivery (standard delivery fee S/ 7.00).
- **Peruvian Addressing & Payments**: Captures label (`Casa`, `Trabajo`, `Previa / Amigos`, `Otro`), Lima district, street and number, interior/floor/Mz-Lt, intercom/buzzer, mandatory delivery reference, and contact phone; supports `Yape`, `Plin`, `Efectivo contra entrega`, and `POS / Tarjeta`.
- **Route Tracking**: Interactive OpenStreetMap tile map with Lima avenue route projection, ETA countdown, courier identity card, and live route progression controls.

## Brand Commitments

- Brand: `WAS-K` (WASK)
- Currency: Peruvian Sol (`S/`)
- Tone: Direct Peruvian Spanish consumer copy, trustworthy and night-ready, free of jargon.
- Local brand assets: `assets/images/logo.jpg` and `assets/images/waskaran.png`.

## Evidence on Hand

- Flutter application structure under `lib/core/` and `lib/features/`, tested with `flutter analyze` and `flutter test`.
- Backend API contract documented in `CLAUDE.md` and `API-Wask` endpoints (`/business/shops`, `/products`, `/orders`, `/orders/loyalty`, `/orders/loyalty/simulate`, `/uploads/*.png`).

## Product Principles

1. **Zero nocturnal glare**: High-contrast dark surfaces calibrated for night use while maintaining >=4.5:1 legibility on prices, stock, and controls.
2. **One-tap momentum**: Move from catalog discovery, store modal, or live search directly into the cart with minimal taps and persistent cart visibility.
3. **Lima-accurate checkout**: Address capture and Yape/Plin payment flows match how Lima customers actually receive and pay for late-night deliveries.
4. **Transparent fulfillment**: Show real stock counts, automatic free-delivery eligibility, loyalty stamp progress, and live street-level courier movement.
