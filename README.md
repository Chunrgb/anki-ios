# Anki iOS

Open-source Anki flashcard app for iOS, built with Flutter and powered by the official Anki Rust core (`rslib`).

## Architecture

```
Flutter UI (Dart + Cupertino)
         ↓ flutter_rust_bridge FFI
   Rust Bridge (anki_bridge)
         ↓ Rust workspace
   rslib (Anki Core — existing)
```

## Features

- **Deck review** with FSRS scheduling (same algorithm as Anki desktop)
- **Card rendering** via WKWebView with full HTML/CSS/mathjax support
- **AnkiWeb sync** — bidirectional sync with your existing collection
- **Browser** — full-text search with Anki query syntax
- **Stats** — study streak, retention rate, 30-day forecast chart
- **Import/Export** — `.apkg` and `.colpkg` via iOS Files app
- **Offline-first** — SQLite collection stored in iOS Documents

## Building (requires macOS)

### Prerequisites

```bash
# Install Flutter (https://flutter.dev/docs/get-started/install/macos)
# Install Xcode 15+ from the App Store
# Install Rust (https://rustup.rs)
brew install cocoapods
```

### Quick build

```bash
git clone https://github.com/ankitects/anki-ios
cd anki-ios
chmod +x build_ios.sh
./build_ios.sh

# Then run on simulator:
flutter run --simulator

# Or open in Xcode for device testing:
open ios/Runner.xcworkspace
```

### Codegen (after modifying the Rust bridge API)

```bash
flutter pub run flutter_rust_bridge_codegen generate
```

## Development on Windows / Linux

You can edit all Dart/Rust code on any platform. The iOS build step requires macOS.

```bash
# Analyze Dart code
flutter analyze

# Run unit tests (uses mock Rust bridge)
flutter test

# Check Rust code
cd rust && cargo check
```

## Project Structure

```
anki-ios/
├── lib/                    Flutter UI
│   ├── screens/            App screens (Decks, Review, Browser, Stats, Settings)
│   ├── providers/          Riverpod state providers
│   ├── widgets/            Reusable widgets
│   ├── services/           AnkiService (bridge wrapper)
│   └── src/rust/           Generated + stub bridge code
├── rust/                   Rust bridge crate (anki_bridge)
│   └── src/api.rs          Public bridge API
├── ios/                    iOS native config
│   ├── Runner/             Swift AppDelegate, Info.plist
│   └── Podfile
├── .github/workflows/      GitHub Actions CI (macOS build)
├── flutter_rust_bridge.yaml  Codegen config
├── build_ios.sh            macOS build script
└── docs/superpowers/specs/ Design documents
```

## rslib Dependency

The `rust/Cargo.toml` references `rslib` via a relative path:

```toml
anki = { path = "../anki-main/anki-main/rslib" }
```

Adjust this path if your `anki` desktop checkout is in a different location.

## License

AGPL-3.0 — same as Anki desktop.
