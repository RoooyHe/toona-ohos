# Toona - Matrix Client for HarmonyOS

## Project Overview

Toona is a Matrix client for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android. Uses **ArkTS strict mode** with MVVM + Repository pattern.

```
toona/src/main/ets/
├── network/           # MatrixHttpClient
├── models/            # DataModels.ets, MatrixTypes.ets
├── database/          # SQLite (LocalDatabase.ets)
├── storage/           # SecureStorage for session tokens
├── services/          # Auth, Sync, Room, Message, Presence
├── pages/             # UI pages
├── viewmodels/        # View models
├── utils/             # ThemeManager, etc.
└── toonaability/      # Entry point
```

## Build Commands

| Command | Description |
|---------|-------------|
| `hvigor build` | Full debug build |
| `hvigor clean` | Clean artifacts |
| `hvigor build -m toona` | Build module |
| `hvigor assembleRelease` | Release build |
| `hvigor build --mode debug` | Debug mode |

### Testing

Tests use `@ohos/hypium` framework. Test location: `toona/src/test/**/*.test.ets`

```bash
# Run all tests via DevEco Studio: hvigor test
# Or run in DevEco Studio: Run > Run All Tests

# Single test: Use DevEco Studio's test runner
# Right-click a test function > Run 'it name'
```

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
- `fetch()` (use `@ohos.net.http`)
- `@ohos.pullToRefresh` (use alternative)
- `placeholderFontColor` (use `placeholderColor`)

### ALWAYS Use
- Explicit type annotations
- Intermediate typed variables for object literals
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
// Group: external -> internal -> local, use relative paths
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

ESLint config: `code-linter.json5` (uses `@typescript-eslint/recommended` + `@performance/recommended`)

Security rules block unsafe crypto usage (`no-unsafe-aes`, `no-unsafe-rsa-*`, etc.)

## Matrix Implementation

- API prefix: `/_matrix/client/v3/` (some Space APIs use `v1/`)
- Session: `SecureStorage` for tokens, restore at Ability level
- Room tags: from sync response `roomState.account_data.events` (type `m.tag`)
- Key types in `models/MatrixTypes.ets`: `Event`, `RoomState`, `LoginResponse`, `MessageEventContent`
- Key classes in `models/DataModels.ets`: `Session`, `Room`, `Message`, `User`

## Common Tasks

### Add API endpoint
1. Method to `MatrixHttpClient.ets`
2. Response type to `MatrixTypes.ets`
3. Wrapper in Manager service

### Add page
1. Create `.ets` in `pages/`
2. Add route to `main_pages.json` (src/main/resources/base/profile/)
3. Register in ToonaAbility if needed

## Configuration

- `main_pages.json`: Route config
- `module.json5`: Permissions (INTERNET), module settings
- `hvigorfile.ts`: Build plugins
