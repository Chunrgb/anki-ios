#!/bin/bash
# build_ios.sh — Build script for Anki iOS (run on macOS with Xcode)
set -euo pipefail

echo "==> Anki iOS Build Script"
echo ""

# ─── Requirements check ──────────────────────────────────────────────────────
command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter not found. Install from https://flutter.dev"; exit 1; }
command -v cargo >/dev/null 2>&1 || { echo "ERROR: Rust not found. Install from https://rustup.rs"; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo "ERROR: Xcode not found. Install from App Store"; exit 1; }

echo "==> Installing Rust iOS targets..."
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add x86_64-apple-ios

echo "==> Getting Flutter dependencies..."
flutter pub get

echo "==> Installing flutter_rust_bridge_codegen..."
cargo install flutter_rust_bridge_codegen --version "^2.0" 2>/dev/null || true

echo "==> Generating Rust bridge bindings..."
flutter_rust_bridge_codegen generate

echo "==> Building Rust library for iOS device (aarch64)..."
cd rust
cargo build --release --target aarch64-apple-ios
echo "==> Building Rust library for iOS Simulator (aarch64)..."
cargo build --release --target aarch64-apple-ios-sim
cd ..

echo "==> Creating XCFramework..."
xcodebuild -create-xcframework \
  -library rust/target/aarch64-apple-ios/release/libanki_bridge.a \
  -library rust/target/aarch64-apple-ios-sim/release/libanki_bridge.a \
  -output ios/Frameworks/AnkiBridge.xcframework

echo "==> Installing CocoaPods..."
cd ios && pod install --repo-update && cd ..

echo ""
echo "==> Build options:"
echo "  Debug on Simulator:  flutter run --simulator"
echo "  Release for device:  flutter build ios --release"
echo "  Open in Xcode:       open ios/Runner.xcworkspace"
echo ""
echo "Build complete!"
