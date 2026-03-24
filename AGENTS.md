# Toona - Matrix Client for HarmonyOS

## Project Overview

Toona is a Matrix client application for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android client architecture. It uses **ArkTS** (strict mode) with MVVM + Repository pattern architecture.

## Build Commands

### Using DevEco Studio (Recommended)
- **Build**: Run ` hvigor build` or use DevEco Studio's Build menu
- **Clean**: Run `hvigor clean`
- **Build Module**: `hvigor build -m toona`
- **Debug Mode**: `hvigor build --mode debug`

### Manual Build
```bash
cd C:\Users\Roy\DevEcoStudioProjects\toona_ohos
hvigor assembleDefault  # Full debug build
hvigor assembleRelease # Release build
```

### Architecture

```
toona/src/main/ets/
├── network/           # HTTP client for Matrix API
├── models/            # Data models and Matrix types
├── database/          # SQLite local storage
├── storage/           # SecureStorage for session tokens
├── services/          # Business logic (Auth, Sync, Room, Message)
├── pages/             # UI pages (Login, Main, RoomDetail, etc.)
├── viewmodels/        # View models for MVVM
└── toonaability/      # Application entry point
```

## Code Style Guidelines

### ArkTS Strict Mode Rules

**NEVER use:**
- `any` or `unknown` types
- Structural typing workarounds
- Destructuring declarations (`const [a, b] = ...`)
- Indexed access for string fields (use helper functions)
- `throw` without Error objects
- `Record<string, object>` (use `Record<string, string | object>`)

**ALWAYS use:**
- Explicit type annotations for variables
- Intermediate typed variables for object literals
- Explicit generic parameters for HTTP methods
- Error handling with try-catch that throws `Error` objects

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `RoomManager`, `Session` |
| Interfaces | PascalCase | `CreateRoomOptions`, `SpaceChild` |
| Enums | PascalCase | `FilterType`, `MessageStatus` |
| Enum Values | PascalCase | `FilterType.ALL`, `MessageStatus.SENT` |
| Private vars | camelCase | `httpClient`, `authManager` |
| Constants | camelCase | `SESSION_KEY`, `PREFS_NAME` |
| Types | PascalCase | `Record<string, string>` |

### Import Style

```typescript
// Group imports by category, use relative paths
import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { Room, Message, Session } from '../models/DataModels';
import { AuthManager } from '../services/AuthManager';
import { SecureStorage } from '../storage/SecureStorage';
```

### Error Handling

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

### Type Definitions

```typescript
// Use explicit types for Record
const content: Record<string, string | object> = {};

// For interface arrays
const initialState: InitialStateEvent[] = [...];

// For callback parameters
onToggle: (roomId: string) => void;
onNavigate: (room: Room) => void;
```

### Component Decorators

Every UI struct MUST have `@Component` decorator:

```typescript
@Entry
@Component
struct MyPage {
  @State data: string = '';
  
  aboutToAppear() {
    // Use this instead of constructor
  }
  
  build() {
    Column() { ... }
  }
}
```

### Property Initialization

Properties must be initialized or have default values:

```typescript
// With default
@State rooms: Room[] = [];
@Prop filterType: FilterType = FilterType.ALL;

// With initialization function
onToggle: (roomId: string) => void = () => {};
```

## Matrix Client Implementation

### API Version
- Use `/_matrix/client/v3/` prefix for most endpoints
- Some Space APIs use `/_matrix/client/v1/`

### Session Management
- Use `SecureStorage` for encrypted token storage
- Session restore happens at **Ability level** (ToonaAbility), NOT in Page's aboutToAppear
- Token validation via `/account/whoami` endpoint

### Room Creation
```typescript
const options: CreateRoomOptions = {
  name: 'Room Name',
  topic?: 'Optional topic',
  isDirect?: true,
  inviteUsers?: ['@user:matrix.org'],
  roomAlias?: 'room-alias'
};
```

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

Key classes in `models/DataModels.ets`:
- `Session` - User session with access token
- `Room` - Room with display name handling
- `Message` - Message with body extraction
- `User` - User profile

## Common Tasks

### Adding a new API endpoint
1. Add method to `MatrixHttpClient.ets`
2. Add response type to `MatrixTypes.ets`
3. Add wrapper in appropriate Manager service

### Adding a new page
1. Create `.ets` file in `pages/`
2. Add route to `main_pages.json`
3. Register in ToonaAbility if needed

### Adding Space API
Matrix spaces use `m.space.child` state events. See `RoomManager.addChildToSpace()` and `removeChildFromSpace()`.

## Configuration

- **main_pages.json**: Route configuration (src/main/resources/base/profile/)
- **module.json5**: App module settings including INTERNET permission
- **code-linter.json5**: ESLint rules for ArkTS
