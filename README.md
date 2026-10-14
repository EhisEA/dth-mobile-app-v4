# DTH Mobile App (v4)

Flutter client for **De9jaSpirit / DTH** — auth, voting, tickets, livestreams, timeline, profile/wallet, and store shopping (merch + live event stores) with orders.

Current app version: **4.0.9+101**

## Stack

- Flutter **3.41.6** (via [FVM](https://fvm.app/)) + Dart SDK `^3.9.2`
- State: Riverpod
- Flavors: `dev` / `prod` (`lib/main_dev.dart`, `lib/main_prod.dart`)
- Config: `config/dev.json`, `config/prod.json` (passed with `--dart-define-from-file`)
- Optional OTA: Shorebird (see Makefile targets)

## Prerequisites

- [FVM](https://fvm.app/) installed and Flutter SDK selected for this repo
- Xcode / Android Studio as needed for iOS and Android
- For iOS setup helpers: `make setup-ios`

## Getting started

```bash
fvm install
fvm flutter pub get
make run-dev    # or: make run-prod
```

Interactive flavor picker:

```bash
make run-app
```

## Common Makefile targets

| Target | Description |
|--------|-------------|
| `make run-dev` / `run-prod` | Run app for a flavor |
| `make build-apk-dev` / `build-apk-prod` | Android APK |
| `make build-aab-dev` / `build-aab-prod` | Android App Bundle |
| `make build-ipa-dev` / `build-ipa-prod` | iOS IPA |
| `make clean-get` | Clean + pub get |
| `make shorebird-release` / `shorebird-patch` | Shorebird release / patch flows |

See `Makefile` and `MAKEFILE.md` for the full list.

## Project layout

```
lib/
  core/           # router, constants, theme, utils
  data/           # models, repos, providers, app state
  features/       # feature modules (UI + view models)
  flavor/         # flavor config
  widgets/        # shared widgets
assets/           # images, svgs, audio, fonts
config/           # per-flavor dart-defines JSON
```

### Feature modules

Notable areas under `lib/features/`:

- **authentication** — login / register / OTP
- **home**, **posts**, **stories**, **livestream**, **notifications**
- **voting**, **polls**, **leaderboard**
- **tickets**, **subscription**, **support**
- **profile** — wallet, bank accounts, withdrawals
- **store** — merch + event catalogs, cart, checkout, addresses, payment result
- **orders** — paid order history, track timeline, reorder into cart
- **application** / **application_dashboard** — contestant application flows

## Store & orders

Store and orders talk to the authenticated store APIs (cart, quote/checkout, addresses, orders list/detail/reorder). Cart UI is scoped by store kind (`merch` vs `event`). Orders are loaded from the API (no mock order data).

## Notes

- Do not commit secrets. Flavor config lives under `config/` and should stay out of public share where sensitive.
- Prefer `make` / FVM commands so flavor + dart-defines stay consistent.
