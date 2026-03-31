# Toona - Matrix Client for HarmonyOS

## Project Overview

Toona is a Matrix client application for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android client architecture. It uses **ArkTS** (strict mode) with MVVM + Repository pattern architecture.

## Build Commands

### Using DevEco Studio (Recommended)
- **Build**: Run `hvigor build` or use DevEco Studio's Build menu
- **Clean**: Run `hvigor clean`
- **Build Module**: `hvigor build -m toona`
- **Debug Mode**: `hvigor build --mode debug`
- **Release Build**: `hvigor assembleRelease`

### Manual Build
```bash
cd C:\Users\Roy\DevEcoStudioProjects\toona_ohos
hvigor assembleDefault  # Full debug build
hvigor assembleRelease # Release build
```

### Testing Commands
```bash
# Run all tests (via DevEco Studio)
hvigor test          # If supported

# Test files use @ohos/hypium framework
# Location: toona/src/test/**/*.test.ets
```

### Lint
```bash
# Lint is configured via code-linter.json5
# Uses @typescript-eslint/recommended rules
```

## Architecture

```
toona/src/main/ets/
├── network/           # HTTP client for Matrix API (MatrixHttpClient)
├── models/            # Data models (DataModels.ets) and Matrix types (MatrixTypes.ets)
├── database/          # SQLite local storage (LocalDatabase.ets)
├── storage/          # SecureStorage for encrypted session tokens
├── services/          # Business logic (Auth, Sync, Room, Message, Presence, etc.)
├── pages/             # UI pages (Login, Main, RoomDetail, RoomList, etc.)
├── viewmodels/        # View models for MVVM
├── utils/            # Utilities (ThemeManager, etc.)
└── toonaability/     # Application entry point
```

## ArkTS Strict Mode Rules

### NEVER use:
- `any` or `unknown` types
- Structural typing workarounds
- Destructuring declarations (`const [a, b] = ...`)
- Indexed access for string fields (use helper functions instead)
- `throw` without Error objects
- `Record<string, object>` - use `Record<string, string | object>`
- Spread operator `...`
- `as unknown as` casts
- `in` operator
- `Object.assign()`
- `@ohos.pullToRefresh` (use alternative)
- `placeholderFontColor` - use `placeholderColor`

### ALWAYS use:
- Explicit type annotations for variables
- Intermediate typed variables for object literals
- Explicit generic parameters for HTTP methods
- Error handling with try-catch that throws `Error` objects
- `fetch()` is NOT supported - use `@ohos.net.http`
- Enum definitions must be top-level (NOT inside classes)

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `RoomManager`, `Session` |
| Interfaces | PascalCase | `CreateRoomOptions`, `SpaceChild` |
| Enums | PascalCase | `FilterType`, `MessageStatus` |
| Enum Values | PascalCase | `FilterType.ALL`, `MessageStatus.SENT` |
| Private vars | camelCase | `httpClient`, `authManager` |
| Constants | camelCase | `SESSION_KEY`, `PREFS_NAME` |
| Types | PascalCase | `Record<string, string>` |

## Import Style

```typescript
// Group imports by category (external -> internal -> local), use relative paths
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { Room, Message, Session } from '../models/DataModels';
import { ThemeManager, getThemeColors } from '../utils/ThemeManager';
```

## Error Handling

```typescript
// CORRECT - throws Error object
try {
  await this.httpClient.post<LoginResponse>('/login', loginBody);
} catch (error) {
  console.error('Login failed:', error);
  const errMsg: string = error instanceof Error ? error.message : String(error);
  throw new Error(`Login failed: ${errMsg}`);
}

// WRONG - throwing non-Error
throw 'something went wrong';  // Never do this
```

## Type Definitions

```typescript
// Use explicit types for Record
const content: Record<string, string | object> = {};

// For interface arrays
const initialState: InitialStateEvent[] = [...];

// For callback parameters - must have default values
onToggle: (roomId: string) => void = () => {};
onNavigate: (room: Room) => void = () => {};
```

## Component Decorators

Every UI struct MUST have `@Component` decorator:

```typescript
@Entry
@Component
struct MyPage {
  @State data: string = '';
  @StorageLink('colorMode') colorMode: number = 0;

  aboutToAppear() {
    // Use this instead of constructor
  }

  build() {
    Column() { ... }
  }
}
```

## Property Initialization

Properties must be initialized or have default values:

```typescript
// With default
@State rooms: Room[] = [];
@Prop filterType: FilterType = FilterType.ALL;

// With initialization function (required for callbacks)
onToggle: (roomId: string) => void = () => {};
```

## ThemeManager Integration

Dark mode is controlled via `ThemeManager` (src/main/ets/utils/ThemeManager.ets):

```typescript
import { ThemeManager, getThemeColors } from '../utils/ThemeManager';

// SettingsPage has toggleDarkMode() method
// Other pages use getThemeColors() for theme-aware colors
private themeManager: ThemeManager = ThemeManager.getInstance();

// Get current theme colors
const colors = getThemeColors();
```

## Matrix Client Implementation

### API Version
- Use `/_matrix/client/v3/` prefix for most endpoints
- Some Space APIs use `/_matrix/client/v1/`

### Session Management
- Use `SecureStorage` for encrypted token storage
- Session restore happens at **Ability level** (ToonaAbility), NOT in Page's aboutToAppear
- Token validation via `/account/whoami` endpoint

### Room Tags
- Tags come from sync response's `roomState.account_data.events` with type `m.tag`
- NOT from separate API endpoint

## Key Patterns

### Singleton Pattern
```typescript
export class RoomManager {
  private static instance: RoomManager;

  static getInstance(): RoomManager {
    if (!RoomManager.instance) {
      RoomManager.instance = new RoomManager();
    }
    return RoomManager.instance;
  }
}
```

### Builder for Complex Objects
```typescript
const createContent: Record<string, string | object> = {
  'creator': userId,
  'room_version': '9',
  'type': 'm.space'
};
```

## Matrix Types Reference

Key interfaces in `models/MatrixTypes.ets`:
- `Event` - Matrix event structure
- `RoomState` - Sync response room state
- `LoginResponse`, `RegisterResponse` - Auth responses
- `MessageEventContent` - Message content structure
- `PresenceState` - online/offline/unavailable

Key classes in `models/DataModels.ets`:
- `Session` - User session with access token
- `Room` - Room with display name handling, tags, avatarUrl
- `Message` - Message with body extraction, status
- `User` - User profile

## Common Tasks

### Adding a new API endpoint
1. Add method to `MatrixHttpClient.ets`
2. Add response type to `MatrixTypes.ets`
3. Add wrapper in appropriate Manager service

### Adding a new page
1. Create `.ets` file in `pages/`
2. Add route to `main_pages.json` (src/main/resources/base/profile/)
3. Register in ToonaAbility if needed

### Adding Space API
Matrix spaces use `m.space.child` state events. See `RoomManager.addChildToSpace()` and `removeChildFromSpace()`.

## Configuration

- **main_pages.json**: Route configuration (src/main/resources/base/profile/)
- **module.json5**: App module settings including INTERNET permission
- **code-linter.json5**: ESLint rules for ArkTS
- **hvigorfile.ts**: Build configuration

## File Structure

```
toona/src/main/
├── ets/
│   ├── main.ets              # App entry
│   ├── pages/               # All page components
│   ├── services/            # Business logic managers
│   ├── models/              # Data models
│   ├── network/             # HTTP client
│   ├── database/            # SQLite
│   ├── storage/             # SecureStorage
│   └── utils/               # Utilities (ThemeManager, etc.)
└── resources/
    └── base/profile/        # main_pages.json
```
