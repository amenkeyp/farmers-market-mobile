# Farmers Market POS – Flutter

Production-ready POS mobile app for the Farmers Market Platform (Côte d'Ivoire).
Offline-first, fintech-grade UI, Clean architecture.

## Stack

- **Flutter 3.x / Dart 3.x**
- **Riverpod** – state management
- **go_router** – navigation
- **Dio** – HTTP client (with auth + retry interceptors)
- **Hive** – local cache & offline queue
- **flutter_secure_storage** – auth token vault
- **connectivity_plus** – online/offline detection
- **google_fonts (Inter)** – typography
- **shimmer** – skeleton loaders

## Architecture

Clean architecture, feature-based:

```
lib/
├── main.dart
├── app/                   # App shell, theme, router
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/                  # Cross-cutting concerns
│   ├── api/               # Dio client, interceptors, ApiResult
│   ├── storage/           # Hive boxes, secure storage
│   ├── network/           # Connectivity service
│   ├── sync/              # Offline queue & sync engine
│   ├── errors/            # Failure types
│   ├── utils/             # Formatters, extensions
│   └── widgets/           # Reusable design-system widgets
└── features/
    ├── auth/
    │   ├── data/          # AuthApi, AuthRepository
    │   ├── domain/        # AuthSession entity
    │   └── presentation/  # LoginScreen, providers
    ├── farmers/
    ├── products/          # categories tree + products
    ├── checkout/          # cart, payment, transactions
    ├── debts/
    └── repayments/
```

### Layers

- **data**: API DTOs, repositories. Talk to backend + Hive cache.
- **domain**: Plain immutable entities + repository interfaces.
- **presentation**: Riverpod notifiers + screens + widgets.

## Backend

Targets the Laravel API at `http://127.0.0.1:8000/api` (configurable via
`--dart-define=API_BASE_URL=https://api.example.com/api`).

Auth: Sanctum bearer token (`POST /auth/login`).

## Offline mode

- Reads (farmers, products, debts) cached in Hive boxes – served instantly
  on cold start, refreshed in background when online.
- Writes (transactions, repayments, farmer creation) are enqueued in the
  `offline_queue` Hive box when offline. The `SyncService` drains the
  queue on reconnect, in submission order.
- Conflict policy: **server-wins** for stale reads; for queued writes the
  client attaches a `client_uuid` so the backend can dedupe replays.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Default credentials (seeded backend):

- email: `admin@market.ci`
- password: `password`

## Design system

- Primary: `#0088CC`
- Surfaces: soft white `#F7F9FC`, cards pure white with 12% black shadow
- Radius: 16dp on cards, 12dp on inputs, 999dp on pills
- Typography: Inter, tabular numerics for money
- Motion: 220ms `easeOutCubic` for transitions
