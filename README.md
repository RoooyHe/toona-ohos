# Toona — Matrix Client for HarmonyOS

<p align="center">
  <img src="./AppScope/resources/base/media/1024.jpg" alt="Toona Logo" width="128" height="128" style="border-radius: 24px;">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS-000000?style=flat-square&logo=huawei" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Matrix-v3-green?style=flat-square&logo=matrix" alt="Matrix">
  <img src="https://img.shields.io/badge/E2EE-Olm/Megolm-orange?style=flat-square" alt="E2EE">
</p>

[中文版](./README_CN.md) | English

A native Matrix client for HarmonyOS, designed around deep-module architecture with strict dependency injection, platform abstraction, and explicit seam boundaries. Modeled after ElementX/Element Android.

## Features

| Category | Features |
|----------|----------|
| **Auth** | Login / Register with homeserver, encrypted token persistence, automatic session restore, token validation |
| **Sync** | Long-polling sync engine, incremental sync with `since` token, room state reconciliation |
| **Rooms** | Create / join / leave rooms, room aliases, public room directory, room settings |
| **Messaging** | Text / emote / notice messages, edit / delete / reply, reactions, stickers, read receipts |
| **Spaces** | Hierarchical room organization, space tree navigation, space creation |
| **E2EE** | Olm/Megolm encryption, device key management, key verification (SAS + QR), device trust levels |
| **Presence** | User presence status, status messages |
| **Media** | Image upload / download, thumbnail generation, URL previews |
| **UI** | Dark / light theme, room tag filtering (favorites, unread, DMs), notification badges |

## Architecture

```
toona/src/main/ets/
├── network/
│   ├── ConnectionConfig.ets       # Token + homeserver seam (pull model)
│   └── clients/
│       ├── BaseHttpClient.ets     # Generic HTTP (request, requestBinary, requestMediaJson, upload)
│       ├── RoomHttpClient.ets     # Room + typing + receipt APIs
│       ├── MessageHttpClient.ets  # Message send + relations APIs
│       ├── UserHttpClient.ets     # User profile APIs
│       ├── DeviceHttpClient.ets   # Device key APIs
│       ├── MediaHttpClient.ets    # Media upload / download / thumbnail
│       ├── PresenceHttpClient.ets # Presence APIs
│       └── OpenIdHttpClient.ets   # OpenID token APIs
├── platform/
│   └── adapters/
│       ├── IFilePicker.ets        # File selection interface
│       ├── IAudioRecorder.ets     # Audio recording interface
│       ├── IClipboard.ets         # Clipboard interface
│       ├── HarmonyFilePicker.ets  # PhotoPicker + file I/O impl
│       ├── HarmonyAudioRecorder.ets # Microphone + AV recorder impl
│       └── HarmonyClipboard.ets   # Pasteboard impl
├── models/
│   ├── DataModels.ets             # Session, Room, Message, User
│   └── types/                     # MatrixTypes, SyncTypes, RoomTypes, MessageTypes, CryptoTypes
├── database/
│   ├── LocalDatabase.ets          # SQLite facade (Room ORM)
│   ├── ToonaDatabase.ets          # Room database definition
│   ├── dao/                       # CryptoDao, DeviceKeysDao, MessageDao, RoomDao, UserDao
│   └── entities/                  # ORM entity classes
├── services/
│   ├── ServiceRegistry.ets        # AppStorage-backed service locator (init/getCurrent)
│   ├── AuthManager.ets            # IAuthManager impl — login, session, token lifecycle
│   ├── SyncManager.ets            # ISyncManager impl — long-polling sync loop
│   ├── RoomManager.ets            # IRoomManager impl — room CRUD
│   ├── MessageManager.ets         # Message send / edit / delete
│   ├── CryptoService.ets          # E2EE: device keys, megolm sessions, decryption
│   ├── VerificationService.ets    # SAS + QR key verification
│   ├── CryptoManager.ets          # Device key upload, one-time key management
│   ├── MediaManager.ets           # Media upload / download / HTTP URL generation
│   ├── DeviceManager.ets          # Device list management
│   ├── FilterManager.ets          # Sync filter CRUD
│   ├── PresenceManager.ets        # Presence state management
│   ├── PushManager.ets            # Push rule management
│   ├── RoomStateManager.ets       # Room state queries
│   ├── RoomTagManager.ets         # Room tag (favorite) management
│   ├── ThirdpartyManager.ets      # Third-party protocol search
│   ├── UserManager.ets            # User profile management
│   ├── VoIPManager.ets            # TURN server credentials
│   ├── OpenIdManager.ets          # OpenID token exchange
│   ├── EventProcessor.ets         # Matrix event dispatch
│   ├── MessageActionHandler.ets   # Message actions (send/edit/delete/pin/react/report/share/copy)
│   ├── MediaActionHandler.ets     # Media actions (pick image / record audio / upload)
│   └── RoomMetadataLoader.ets     # Room topic + member presence + typing
├── pages/
│   ├── AppNavigation.ets          # Root composition root (creates all services)
│   ├── LoginPage.ets              # Login / register
│   ├── MainPage.ets               # Shell with tabs (rooms / spaces)
│   ├── RoomListPage.ets           # Room list with filtering
│   ├── SpacePage.ets              # Space tree navigation
│   ├── RoomDetailPage.ets         # Chat view (composition root for handlers + adapters)
│   ├── SettingsPage.ets           # User settings + device management
│   └── ...                        # SearchPage, JoinRoomPage, JoinSpacePage, etc.
├── pages/components/
│   ├── MessageBubble.ets          # Message display (receives mediaManager + verificationService)
│   ├── ImageViewer.ets            # Full-screen image (receives mediaManager)
│   ├── FilePreview.ets            # File attachment preview
│   └── verification/              # QrCodeVerificationDialog, SasVerificationDialog, VerificationRequestDialog
├── crypto/
│   ├── OlmWrapper.ets             # libolm bindings
│   └── types/CryptoTypes.ets      # Crypto type definitions
├── utils/
│   ├── AppLogger.ets              # Structured logging
│   ├── ThemeManager.ets           # Theme + color system
│   ├── MxcUtils.ets               # mxc:// URL handling
│   ├── MessageFormatter.ets       # Pure formatting functions (time, reply sender)
│   ├── RoomStateParser.ets        # Room state event → Room model
│   └── ToastUtils.ets             # Toast notifications
└── toonaability/                  # ToonaAbility entry point
```

### Design Principles

**Deep Modules, Shallow Frameworks.** Each service has a narrow public interface (`IAuthManager`, `IRoomManager`, `ISyncManager`) and hides implementation detail behind it. Cross-cutting concerns (file picking, audio recording, clipboard) are abstracted behind platform adapter interfaces.

**Constructor Injection, No Hidden Singletons.** All services receive dependencies via constructor parameters. The composition root (`AppNavigation.initializeServices()`) wires the entire graph. No service reaches for `getInstance()` internally — the only `getInstance()` calls are for Room ORM DAOs at initialization time.

**Platform Seams.** `IFilePicker`, `IAudioRecorder`, `IClipboard` isolate HarmonyOS SDK APIs behind interfaces. Business logic depends on the interface; pages construct the Harmony implementation.

**Service Registry as Bounded Locator.** NavDestination pages (instantiated by the Navigation framework) use `ServiceRegistry.getCurrent()` to access services. This is the only legitimate use of the locator — inline child `@Component` pages receive deps via parent-passed properties.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | HarmonyOS + ArkTS strict mode |
| Architecture | MVVM + Repository + Constructor Injection |
| Navigation | NavPathStack / NavDestination (not `@ohos.router`) |
| Storage | SQLite via `@mlethe/room` ORM + `SPHelper` encrypted prefs |
| Network | `@kit.NetworkKit` HTTP client via `BaseHttpClient` |
| Crypto | libolm (Olm + Megolm) via `OlmWrapper` |

### Dependency Graph

```
AppNavigation (composition root)
 ├── ConnectionConfig ←── AuthManager, all HttpClients
 ├── AuthManager (IAuthManager) ←── SyncManager, RoomManager, MessageManager, ...
 ├── CryptoDao + DeviceKeysStorage ←── CryptoService, VerificationService
 ├── CryptoService ←── EventProcessor ←── SyncManager
 ├── Platform Adapters ←── MediaActionHandler, MessageActionHandler ←── RoomDetailPage
 └── ServiceRegistry (AppStorage-backed) ←── NavDestination pages
```

## Getting Started

### Prerequisites

- [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) 5.0+
- HarmonyOS SDK (API 12+)
- Node.js 18+ (for hvigor build system)

### Build

```bash
# Debug build
hvigor build -m toona

# Full project build
hvigor build

# Clean artifacts
hvigor clean

# Release build
hvigor assembleRelease
```

### Run

1. Open project in DevEco Studio
2. Connect a HarmonyOS device or launch an emulator
3. Select `toona` module → Run

## Navigation Architecture

The app uses **NavPathStack / NavDestination** exclusively (not `@ohos.router`).

| Page | Type | Navigation |
|------|------|-----------|
| `AppNavigation` | `@Entry` root | `Navigation(pathStack)` — loads LoginPage or MainPage |
| `LoginPage` | NavDestination | First screen; replaced by MainPage after login |
| `MainPage` | NavDestination | Shell with RoomListPage + SpacePage tabs |
| `RoomDetailPage` | NavDestination | Chat view, pushed via `pushPathByName('RoomDetailPage', { roomId, roomName })` |
| `SettingsPage` | NavDestination | Settings, pushed via `pushPathByName('SettingsPage', ...)` |
| `RoomListPage` | `@Component` child | Embedded inline by MainPage, receives `ISyncManager`, `IRoomManager`, `RoomTagManager` via props |
| `SpacePage` | `@Component` child | Embedded inline by MainPage, receives `IRoomManager` via props |

Child pages are navigated to with:

```typescript
this.pathStack.pushPathByName('RoomDetailPage', {
  "roomId": room.id,
  "roomName": room.getDisplayName()
} as Record<string, string>);
```

## Adding a New Feature

### 1. Add API Endpoint

Add a method to the appropriate `*HttpClient.ets`:

```typescript
// In RoomHttpClient.ets:
async getRoomTags(userId: string): Promise<RoomTagsResponse> {
  const encodedUserId = encodeURIComponent(userId);
  return await this.get<RoomTagsResponse>(`/user/${encodedUserId}/account_data/m.tag`);
}
```

If the API is trivially shallow (1 method, just wrapping `get`/`post`), add it to an existing client — don't create a new one.

### 2. Add Response Type

Define the response type in `models/types/MatrixTypes.ets`.

### 3. Add Service Method

Add a method to the appropriate Manager, or create a new Manager if it's a new domain.

### 4. Add Page

1. Create `.ets` in `pages/`
2. Add a `@Builder` export function (required by `router_map.json`):

```typescript
@Builder
export function MyPageBuilder(name: string, param: Object) {
  MyPage()
}
```

3. Register in `resources/base/profile/router_map.json` and `main_pages.json`
4. If it's an inline child `@Component`, receive deps via props (not ServiceRegistry)

### 5. Wire in Composition Root

For new services: create instance in `AppNavigation.initializeServices()`, register in `ServiceRegistry`.

## Testing

- **Unit tests**: `toona/src/test/**/*.test.ets` — run via DevEco Studio test runner or `hvigor test`
- **On-device tests**: `toona/src/ohosTest/ets/test/*.test.ets`
- **Framework**: `@ohos/hypium`

## Code Style

This project enforces **ArkTS strict mode** (`arkts-*` rule tags):

| Rule | Description |
|------|------------|
| `arkts-no-standalone-this` | No `this` outside class methods |
| `arkts-no-untyped-obj-literals` | Object literals must have explicit type context |
| `arkts-no-any-unknown` | No `any` or `unknown` types |
| `arkts-no-destructuring` | No destructuring declarations |
| `arkts-no-as-const` | No `as const` assertions |

Additional conventions:
- Explicit type annotations on all variables and parameters
- `throw new Error(...)` — never throw strings
- `NavPathStack` / `NavDestination` — never `@ohos.router`
- Constructor injection — never `getInstance()` inside service classes
- `@kit.NetworkKit` HTTP — never `fetch()`

See [AGENTS.md](AGENTS.md) for the complete specification.

## License

MIT License

## Contributing

Contributions are welcome! Please:

1. Read [AGENTS.md](AGENTS.md) for coding standards
2. Follow the architecture patterns (constructor injection, platform adapters, ServiceRegistry boundary)
3. Ensure `hvigor build` passes with zero new errors before submitting PRs
