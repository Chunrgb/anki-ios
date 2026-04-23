# Anki iOS App — Design Spec
**Date:** 2026-04-23  
**Approach:** Flutter + flutter_rust_bridge (Option 2)

---

## 1. Overview

Create a full-featured Anki iOS app that reuses the existing `rslib` Rust core from the desktop codebase. The app targets iPhone/iPad running iOS 15+.

**Key goals:**
- Feature parity with AnkiMobile for core review workflow
- Native iOS Cupertino look and feel
- AnkiWeb sync
- Offline-first with SQLite collection on device
- Open source (AGPL-3.0)

---

## 2. Architecture

```
┌──────────────────────────────────────────────┐
│              Flutter UI (Dart)                │
│  Cupertino widgets, state via Riverpod        │
│                                              │
│  DeckListScreen  ReviewScreen                │
│  BrowserScreen   SettingsScreen              │
└──────────────────┬───────────────────────────┘
                   │ flutter_rust_bridge (async FFI)
┌──────────────────▼───────────────────────────┐
│          anki_bridge (Rust crate)             │
│  Thin wrapper exposing rslib through          │
│  flutter_rust_bridge-generated bindings       │
│                                              │
│  open_collection / close_collection          │
│  get_deck_tree → Vec<DeckNode>               │
│  get_due_counts → DueCounts                  │
│  get_next_card → Option<CardForReview>       │
│  answer_card(id, ease, time_taken)           │
│  sync_collection(username, password)         │
│  search_notes(query) → Vec<NoteInfo>         │
└──────────────────┬───────────────────────────┘
                   │ Rust workspace dependency
┌──────────────────▼───────────────────────────┐
│           rslib (existing Anki Core)          │
│  Collection, Deck, Card, Scheduler (FSRS)    │
│  AnkiWeb sync client, SQLite storage         │
│  Import/Export (.apkg, .colpkg)              │
└──────────────────────────────────────────────┘
```

---

## 3. Technology Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter 3.x (Dart), Cupertino widgets |
| State | Riverpod 2 |
| FFI bridge | flutter_rust_bridge 2.x |
| Core logic | rslib (existing Rust crate) |
| Storage | SQLite via rslib (bundled rusqlite) |
| Sync | AnkiWeb via rslib sync module |
| iOS build | Xcode 15+, iOS 15+ deployment target |
| CI/CD | GitHub Actions (macos-latest runner) |

---

## 4. Screens

### 4.1 HomeScreen
- Collection stats (total cards, studied today, retention rate)
- Quick "Study Now" button → most due deck
- Bottom tab bar: Decks / Browser / Stats / Settings

### 4.2 DeckListScreen (tab: Decks)
- Hierarchical deck tree with expand/collapse
- Per-deck pill badges: New (blue) / Learn (red) / Due (green)
- Tap deck → ReviewScreen
- Long press → deck options (rename, delete, options)
- Pull-to-refresh syncs with AnkiWeb

### 4.3 ReviewScreen
- Full-screen card rendering (HTML/CSS via WKWebView)
- Tap anywhere to show answer
- Answer buttons: Again / Hard / Good / Easy (with scheduling preview)
- Swipe left = Again, Swipe right = Good (gesture shortcuts)
- Progress bar showing remaining cards
- Edit button → opens note editor

### 4.4 BrowserScreen (tab: Browser)
- Search bar with Anki query syntax
- Card list with note, deck, due date columns
- Tap card → preview / edit

### 4.5 StatsScreen (tab: Stats)
- Today's stats: studied, time, retention
- 30-day forecast chart
- Streak counter

### 4.6 SettingsScreen (tab: Settings)
- AnkiWeb account (login/logout, sync status)
- Display preferences (font size, night mode)
- Storage (backup, export)
- About

---

## 5. Rust Bridge API

```rust
// anki_bridge/src/api.rs

pub fn open_collection(path: String) -> Result<()>;
pub fn close_collection() -> Result<()>;
pub fn get_deck_tree() -> Result<Vec<DeckNode>>;
pub fn get_due_counts(deck_id: i64) -> Result<DueCounts>;
pub fn get_next_card(deck_id: i64) -> Result<Option<CardForReview>>;
pub fn answer_card(card_id: i64, ease: u8, time_taken_ms: u32) -> Result<()>;
pub fn get_card_html(card_id: i64, side: CardSide) -> Result<String>;
pub fn search_notes(query: String, limit: u32) -> Result<Vec<NoteInfo>>;
pub fn sync_collection(username: String, password: String) -> Result<SyncStatus>;
pub fn import_apkg(path: String) -> Result<ImportResult>;

// Structs (frb mirror)
pub struct DeckNode { pub id: i64, pub name: String, pub new_count: u32, pub learn_count: u32, pub due_count: u32, pub children: Vec<DeckNode> }
pub struct DueCounts { pub new: u32, pub learn: u32, pub due: u32 }
pub struct CardForReview { pub id: i64, pub question_html: String }
pub struct NoteInfo { pub id: i64, pub note_type: String, pub fields: Vec<String>, pub tags: Vec<String>, pub deck_name: String, pub due: String }
pub struct SyncStatus { pub success: bool, pub message: String }
pub struct ImportResult { pub notes_added: u32, pub notes_updated: u32 }
pub enum CardSide { Question, Answer }
```

---

## 6. Flutter State (Riverpod)

```
collectionProvider          → AsyncValue<bool>  (collection open?)
deckTreeProvider            → AsyncValue<List<DeckNode>>
currentDeckProvider         → StateProvider<DeckNode?>
currentCardProvider         → AsyncValue<CardForReview?>
reviewSessionProvider       → StateNotifier<ReviewSession>
syncStatusProvider          → StateNotifier<SyncState>
```

---

## 7. Project Structure

```
anki-ios/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # CupertinoApp root
│   ├── screens/
│   │   ├── home/home_screen.dart
│   │   ├── decks/deck_list_screen.dart
│   │   ├── review/review_screen.dart
│   │   ├── browser/browser_screen.dart
│   │   ├── stats/stats_screen.dart
│   │   └── settings/settings_screen.dart
│   ├── widgets/
│   │   ├── deck_tile.dart
│   │   ├── card_web_view.dart
│   │   ├── answer_buttons.dart
│   │   └── due_badge.dart
│   ├── providers/
│   │   ├── collection_provider.dart
│   │   ├── deck_provider.dart
│   │   ├── review_provider.dart
│   │   └── sync_provider.dart
│   └── services/
│       └── anki_service.dart           # Wraps generated bridge
├── rust/
│   ├── Cargo.toml
│   └── src/
│       └── api.rs
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── Runner.entitlements
│   ├── Podfile
│   └── Runner.xcworkspace/
├── android/                            # Future Android support
├── pubspec.yaml
├── build_ios.sh                        # Script para build no macOS
└── .github/workflows/ios-build.yml
```

---

## 8. iOS-Specific Considerations

- **Collection path**: `NSDocumentDirectory/anki.anki2` (auto-backed-up via iCloud)
- **WKWebView**: Card HTML rendered with `webview_flutter` package, custom CSS injected
- **Keyboard shortcuts**: iPad external keyboard support
- **Background sync**: `BGTaskScheduler` for periodic AnkiWeb sync
- **File sharing**: `UIFileSharingEnabled` for .apkg import/export via Files app
- **Haptic feedback**: `UIImpactFeedbackGenerator` on card answer

---

## 9. Build Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 13+ |
| Xcode | 15+ |
| Flutter | 3.19+ |
| Rust | 1.80+ |
| flutter_rust_bridge | 2.x |
| iOS Deployment Target | 15.0 |

**Rust targets needed (on macOS):**
```bash
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add x86_64-apple-ios
```

---

## 10. CI/CD (GitHub Actions)

`.github/workflows/ios-build.yml` runs on `macos-latest`:
1. Checkout repo + submodule (rslib)
2. Install Rust targets for iOS
3. Install Flutter
4. Run `flutter_rust_bridge_codegen`
5. `flutter build ios --release --no-codesign`
6. Upload .app artifact

---

## 11. Phased Delivery

| Phase | Scope |
|-------|-------|
| **P1** (this session) | Project scaffold, Rust bridge, DeckListScreen, ReviewScreen |
| P2 | BrowserScreen, BrowserSearch, Note editor |
| P3 | Stats, AnkiWeb sync UI, Background sync |
| P4 | iPad optimization, widgets, Shortcuts |
