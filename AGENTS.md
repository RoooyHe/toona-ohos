# Toona - Matrix Client for HarmonyOS

## Project Overview

Toona is a Matrix client for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android. Uses **ArkTS strict mode** with MVVM + Repository pattern.

## Build Commands

| Command | Description |
|---------|-------------|
| `hvigor build -m toona` | Build the toona module (standard dev command) |
| `hvigor build` | Full root build |
| `hvigor clean` | Clean artifacts |
| `hvigor assembleRelease` | Release build |

## Testing

Framework: `@ohos/hypium`

- Unit tests: `toona/src/test/**/*.test.ets` — run via DevEco Studio test runner or `hvigor test`
- Ohos tests: `toona/src/ohosTest/ets/test/*.test.ets`
- Single test: right-click a test function in DevEco Studio > Run.

## Navigation Architecture

Uses **NavPathStack / NavDestination** (NOT `@ohos.router`).

### Entry point
`ToonaAbility.ets` calls `windowStage.loadContent('pages/LoginPage')` — this is the sole entry. All further navigation uses `NavPathStack.pushPathByName()`.

### Two @Entry container pages
Both are full navigation containers with their own `NavDestination()` + `NavPathStack`:

| Page | Role |
|------|------|
| `LoginPage` | Loaded first by `loadContent`. Replaced by MainPage after login. |
| `MainPage` | Main app shell with tabs (message list / spaces). |

### Child pages (no @Entry, no NavDestination)
Receive `pathStack` via `@Prop` from the parent container:

| Page | Decorator | pathStack |
|------|-----------|-----------|
| `RoomDetailPage` | `@Component` | `@Prop pathStack: NavPathStack` |
| `SearchPage` | `@Component` | `@Prop pathStack: NavPathStack` |
| `JoinRoomPage` | `@Component` | `@Prop pathStack: NavPathStack` |
| `JoinSpacePage` | `@Component` | `@Prop pathStack: NavPathStack` |
| `SettingsPage` | `@Component` | `@Prop pathStack: NavPathStack` |

### NavPathStack pattern for @Entry containers
```typescript
@Entry
@Component
struct MyContainerPage {
  @State pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      // content, may include child pages via pushPathByName
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
```

### Navigation to replace current container (e.g. Login → Main)
```typescript
this.pathStack.clear();
this.pathStack.pushPathByName('MainPage', undefined);
```
`replacePath(NavPathInfo)` is unreliable on root containers — use `clear()` + `pushPathByName()` instead.

### Navigation to push child pages
```typescript
this.pathStack.pushPathByName('RoomDetailPage', { "roomId": room.id, "roomName": room.getDisplayName() } as Record<string, string>);
```

## Adding a Page

1. Create `.ets` in `toona/src/main/ets/pages/`
2. Add a `@Builder` export function (required by `router_map.json`):
   ```typescript
   @Builder
   export function MyPageBuilder(name: string, param: Object) {
     MyPage({ ... })
   }
   ```
3. Add entry to `router_map.json`:
   ```json
   {
     "name": "MyPage",
     "pageSourceFile": "src/main/ets/pages/MyPage.ets",
     "buildFunction": "MyPageBuilder"
   }
   ```
4. Add page name to `main_pages.json` `src` array

## Code Style

### NEVER Use
- `any` or `unknown` types
- Destructuring (`const [a, b] = ...`)
- Spread operator `...`
- `as unknown as` casts
- `in` operator
- `Object.assign()`
- `throw` without Error objects
- `Record<string, object>` (use `Record<string, string | object>`)
- `fetch()` — use `@ohos.net.http`
- `@ohos.pullToRefresh`
- `placeholderFontColor` (use `placeholderColor`)
- `@ohos.router` — use `NavPathStack` / `NavDestination`

### ALWAYS Use
- Explicit type annotations; intermediate typed variables for object literals
- Explicit generic parameters for HTTP methods
- Try-catch that throws `Error` objects
- Top-level enum definitions (NOT inside classes)
- `@Component` decorator on every UI struct
- Property initialization or defaults
- `NavDestination()` in `build()` for `@Entry` pages
- `@Builder` export function above page struct (for router_map registration)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes/Interfaces/Enums | PascalCase | `RoomManager`, `FilterType` |
| Enum Values | PascalCase | `FilterType.ALL` |
| Private vars/constants | camelCase | `httpClient`, `SESSION_KEY` |
| Types | PascalCase | `Record<string, string>` |

### Import Style
```typescript
// Group order: external -> internal -> local, use relative paths
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { Room, Message } from '../models/DataModels';
```

### Error Handling
```typescript
// CORRECT
try {
  await this.httpClient.post<LoginResponse>('/login', body);
} catch (error) {
  const errMsg: string = error instanceof Error ? error.message : String(error);
  throw new Error(`Login failed: ${errMsg}`);
}

// WRONG - never throw strings
throw 'something went wrong';
```

### Component Structure

**@Entry container page** (has NavDestination, owns NavPathStack):
```typescript
@Builder
export function ContainerPageBuilder(name: string, param: Object) {
  ContainerPage()
}

@Entry
@Component
struct ContainerPage {
  @State pathStack: NavPathStack = new NavPathStack();
  onCallback: (id: string) => void = () => {};

  aboutToAppear() { }

  build() {
    NavDestination() {
      // content
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
```

**Child page** (no @Entry, no NavDestination, receives pathStack via @Prop):
```typescript
@Builder
export function ChildPageBuilder(name: string, param: Object) {
  ChildPage({
    someId: (param as Record<string, string>)['someId'] || ''
  })
}

@Component
struct ChildPage {
  @State someId: string = '';
  @Prop pathStack: NavPathStack;

  build() {
    Column() { /* content */ }
  }
}
```

## Lint

ESLint config: `code-linter.json5`
- Rule sets: `@typescript-eslint/recommended` + `@performance/recommended`
- Security rules (error): `no-unsafe-aes`, `no-unsafe-hash`, `no-unsafe-dh`, `no-unsafe-dsa`, `no-unsafe-ecdsa`, `no-unsafe-rsa-*`, `no-unsafe-3des`
- Ignores: `ohosTest`, `test`, `mock`, `node_modules`, `oh_modules`, `build`, `.preview`

## Matrix Implementation

- API prefix: `/_matrix/client/v3/` (some Space APIs use `v1/`)
- Session: `SecureStorage` for tokens, restored at Ability level
- Room tags: from sync response `roomState.account_data.events` (type `m.tag`)
- HTTP clients: `network/clients/*.ets` (Message, Room, User, Presence, Media, etc.)
- Matrix types: `models/types/*.ets` (SyncTypes, RoomTypes, MessageTypes, etc.)
- Data models: `models/DataModels.ets` (Session, Room, Message, User)

## Configuration

- `main_pages.json` + `router_map.json`: both in `toona/src/main/resources/base/profile/`
- `module.json5`: permissions (INTERNET), ToonaAbility mainElement, ToonaBackupAbility extension
- `build-profile.json5`: strict mode enabled (`caseSensitiveCheck`, `useNormalizedOHMUrl`)

## Common Tasks

### Add API endpoint
1. Method to `network/clients/*HttpClient.ets` (per-feature)
2. Response type to `models/types/*.ets`
3. Wrapper in corresponding Manager service

### Project Structure
```
toona/src/main/ets/
├── network/clients/     # Per-feature HTTP clients (Message, Room, User, etc.)
├── network/             # MatrixHttpClient (entry point)
├── models/types/        # Matrix type definitions (Event, RoomState, etc.)
├── models/              # DataModels.ets (Session, Room, Message, User)
├── database/            # SQLite (LocalDatabase.ets)
├── storage/             # SecureStorage for session tokens
├── services/            # Auth, Sync, Room, Message, Presence managers
├── pages/               # UI pages
├── utils/               # ThemeManager, MxcUtils
├── toonaability/        # Entry point (ToonaAbility)
├── toonabackupability/  # Backup extension ability
└── toonacontinueability/# Continue ability
```
