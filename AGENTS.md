# Toona - Matrix Client for HarmonyOS

## Project Overview

Toona is a Matrix client for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android. Uses **ArkTS strict mode** with MVVM + Repository pattern.

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

Single test: right-click a test function in DevEco Studio > Run.

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

### ALWAYS Use
- Explicit type annotations; intermediate typed variables for object literals
- Explicit generic parameters for HTTP methods
- Try-catch that throws `Error` objects
- Top-level enum definitions (NOT inside classes)
- `@Component` decorator on every UI struct
- Property initialization or defaults

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
import router from '@ohos.router';
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
```typescript
@Entry
@Component
struct MyPage {
  @State data: string = '';
  @StorageLink('colorMode') colorMode: number = 0;
  onCallback: (id: string) => void = () => {};  // callbacks need defaults

  aboutToAppear() { }  // Use instead of constructor

  build() {
    Column() { }
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

### Add page
1. Create `.ets` in `toona/src/main/ets/pages/`
2. Add page sourceFile + buildFunction to `router_map.json`
3. Add page name to `main_pages.json` src list
4. Register in `ToonaAbility` if needed