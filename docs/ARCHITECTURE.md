# Toona Matrix Client — Architecture Overview

**Date:** 2026-07-07  
**Platform:** HarmonyOS (ArkTS strict mode)  
**Architecture:** MVVM + Repository Pattern

---

## Project Structure

```
toona/
├── src/
│   ├── main/
│   │   ├── ets/
│   │   │   ├── network/
│   │   │   │   ├── MatrixHttpClient.ets          # Entry point, HTTP client factory
│   │   │   │   └── clients/
│   │   │   │       ├── BaseHttpClient.ets        # Base HTTP client with auth
│   │   │   │       ├── MediaHttpClient.ets       # Media upload/download
│   │   │   │       ├── RoomHttpClient.ets        # Room state, members, receipts
│   │   │   │       ├── MessageHttpClient.ets     # Typing, relations, annotations
│   │   │   │       ├── UserHttpClient.ets        # Profile, push rules, tags
│   │   │   │       ├── DeviceHttpClient.ets      # Devices, crypto keys
│   │   │   │       ├── PresenceHttpClient.ets    # Presence status
│   │   │   │       ├── FilterHttpClient.ets      # Sync filters
│   │   │   │       ├── ThirdpartyHttpClient.ets  # Thirdparty protocols
│   │   │   │       ├── OpenIdHttpClient.ets      # OpenID tokens
│   │   │   │       └── VoipHttpClient.ets        # TURN credentials
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── DataModels.ets                # Core models: Session, Room, Message, User
│   │   │   │   └── types/
│   │   │   │       ├── SyncTypes.ets             # Sync response types
│   │   │   │       ├── RoomTypes.ets             # Room state types
│   │   │   │       ├── MessageTypes.ets          # Message content types
│   │   │   │       ├── EventTypes.ets            # Event envelope types
│   │   │   │       ├── DeviceTypes.ets           # Device and crypto types
│   │   │   │       └── PushTypes.ets             # Push rule types
│   │   │   │
│   │   │   ├── database/
│   │   │   │   ├── ToonaDatabase.ets             # ORM schema definition
│   │   │   │   ├── LocalDatabase.ets             # DAO facade (513 lines)
│   │   │   │   ├── entities/
│   │   │   │   │   ├── MessageEntity.ets
│   │   │   │   │   ├── RoomEntity.ets
│   │   │   │   │   ├── UserEntity.ets
│   │   │   │   │   └── RoomMemberEntity.ets
│   │   │   │   └── converters/
│   │   │   │       ├── ContentConverter.ets      # JSON serialization
│   │   │   │       └── TagsConverter.ets         # Tag map persistence
│   │   │   │
│   │   │   ├── services/
│   │   │   │   ├── AuthManager.ets               # Authentication
│   │   │   │   ├── SyncManager.ets               # Long-poll sync
│   │   │   │   ├── RoomManager.ets               # Room operations
│   │   │   │   ├── MessageManager.ets            # Message operations
│   │   │   │   ├── MediaManager.ets              # Media operations
│   │   │   │   ├── UserManager.ets               # User profile
│   │   │   │   ├── PresenceManager.ets           # Presence
│   │   │   │   ├── DeviceManager.ets             # Devices
│   │   │   │   ├── PushManager.ets               # Push rules
│   │   │   │   ├── RoomStateManager.ets          # Room state
│   │   │   │   ├── RoomTagManager.ets            # Room tags
│   │   │   │   ├── EventProcessor.ets            # Event routing
│   │   │   │   ├── FilterManager.ets             # Sync filters
│   │   │   │   ├── ShareManager.ets              # Sharing
│   │   │   │   ├── ThirdpartyManager.ets         # Thirdparty
│   │   │   │   ├── OpenIdManager.ets             # OpenID
│   │   │   │   ├── VoIPManager.ets               # VoIP
│   │   │   │   ├── ScanManager.ets               # QR scanning
│   │   │   │   ├── CryptoManager.ets             # Crypto keys
│   │   │   │   ├── UserAuthManager.ets           # Biometric auth (stub)
│   │   │   │   ├── DeviceSecurityManager.ets     # Security analysis
│   │   │   │   ├── ServiceCollaborationManager.ets # Collaboration (stub)
│   │   │   │   └── MediaLibraryManager.ets       # Media library
│   │   │   │
│   │   │   ├── pages/
│   │   │   │   ├── LoginPage.ets                 # @Entry: Login
│   │   │   │   ├── RegisterPage.ets              # @Entry: Register
│   │   │   │   ├── MainPage.ets                  # @Entry: Main shell
│   │   │   │   ├── RoomListPage.ets              # Room list
│   │   │   │   ├── RoomDetailPage.ets            # Chat view
│   │   │   │   ├── SpacePage.ets                 # Spaces
│   │   │   │   ├── SpaceDetailPage.ets           # Space children
│   │   │   │   ├── SearchPage.ets                # Search
│   │   │   │   ├── JoinRoomPage.ets              # Join room
│   │   │   │   ├── JoinSpacePage.ets             # Join space
│   │   │   │   ├── SettingsPage.ets              # Settings
│   │   │   │   └── components/
│   │   │   │       ├── MessageBubble.ets         # Message display
│   │   │   │       ├── MessageInputBar.ets       # Message input
│   │   │   │       ├── EditMessage.ets           # Message editing
│   │   │   │       ├── ReplyQuote.ets            # Reply context
│   │   │   │       ├── MessageActionMenu.ets     # Context menu
│   │   │   │       ├── MemberListPanel.ets       # Member list
│   │   │   │       └── settings/                 # 12 settings components
│   │   │   │
│   │   │   ├── storage/
│   │   │   │   └── SecureStorage.ets             # Session token persistence
│   │   │   │
│   │   │   ├── utils/
│   │   │   │   ├── ThemeManager.ets              # Theme system (20+ tokens)
│   │   │   │   ├── MxcUtils.ets                  # MXC URI utilities
│   │   │   │   ├── AppLogger.ets                 # Logging
│   │   │   │   └── ToastUtils.ets                # Toast notifications
│   │   │   │
│   │   │   ├── toonaability/
│   │   │   │   └── ToonaAbility.ets              # App entry point
│   │   │   │
│   │   │   └── toonabackupability/               # Backup extension
│   │   │
│   │   └── resources/
│   │       └── base/profile/
│   │           ├── main_pages.json               # Page registry
│   │           └── router_map.json               # Route definitions
│   │
│   └── test/                                     # Unit tests
│
├── DESIGN.md                                     # Design system spec
├── AGENTS.md                                     # Agent instructions
└── build-profile.json5                           # Build config
```

---

## Key Abstractions

### BaseHttpClient
**File:** `network/clients/BaseHttpClient.ets`

All HTTP clients extend this base class which provides:
- Bearer token injection
- JSON request/response serialization
- HTTP verb methods (get, post, put, delete)
- UIA 401 detection for interactive authentication
- Media upload with filename support

```typescript
class BaseHttpClient {
  protected httpClient: http.HttpRequest;
  protected baseUrl: string;
  
  async get<T>(path: string, body?: Object): Promise<T>
  async post<T>(path: string, body?: Object): Promise<T>
  async put<T>(path: string, body?: Object): Promise<T>
  async delete(path: string): Promise<void>
  async uploadMedia(filePath: string, filename: string): Promise<UploadResponse>
}
```

### EventProcessor
**File:** `services/EventProcessor.ets`

Central event router that processes sync timeline events and dispatches to appropriate handlers:

| Event Type | Handler |
|------------|---------|
| `m.room.message` | Message processing |
| `m.room.member` | Member join/leave/kick/ban |
| `m.room.name` | Room name update |
| `m.room.topic` | Room topic update |
| `m.room.avatar` | Room avatar update |
| `m.room.redaction` | Message redaction |
| `m.room.encrypted` | Encrypted event storage |
| `m.sticker` | Sticker event processing |
| `m.presence` | Presence update |

### LocalDatabase (Facade)
**File:** `database/LocalDatabase.ets` (513 lines)

Provides bidirectional mapping between ORM entities and domain models:
- `MessageEntity` ↔ `Message`
- `RoomEntity` ↔ `Room`
- `UserEntity` ↔ `User`
- `RoomMemberEntity` ↔ `RoomMember`

Full CRUD operations for all four tables with reactive queries.

---

## Data Flow

### Sync Flow
```
SyncManager.start()
  │
  ├─→ HTTP GET /sync (long-poll)
  │     │
  │     ├─→ Process joined rooms
  │     │     │
  │     │     ├─→ Room state changes → RoomManager.updateRoomState()
  │     │     ├─→ Timeline events → EventProcessor.processEvent()
  │     │     │     │
  │     │     │     ├─→ m.room.message → MessageManager.processMessage()
  │     │     │     ├─→ m.room.member → RoomManager.processMemberEvent()
  │     │     │     ├─→ m.room.encrypted → EventProcessor.processEncryptedEvent()
  │     │     │     └─→ m.presence → PresenceManager.processPresenceEvent()
  │     │     │
  │     │     └─→ Update database via LocalDatabase
  │     │
  │     ├─→ Process invited rooms → RoomManager.processInvite()
  │     ├─→ Process left rooms → RoomManager.processLeave()
  │     ├─→ Process account data → RoomTagManager.processAccountData()
  │     └─→ Process to-device events → (not implemented)
  │
  └─→ Notify UI via callbacks
        │
        ├─→ RoomListPage refreshes
        ├─→ RoomDetailPage refreshes
        └─→ MainPage updates unread counts
```

### Message Send Flow
```
User types message
  │
  ├─→ MessageInputBar.onInputChange()
  │
  ├─→ User presses send
  │     │
  │     ├─→ MessageManager.sendMessage()
  │     │     │
  │     │     ├─→ Generate event content
  │     │     ├─→ Generate transaction ID
  │     │     │
  │     │     ├─→ Try HTTP PUT /rooms/{id}/send/{type}/{txnId}
  │     │     │     │
  │     │     │     ├─→ Success → Save to database
  │     │     │     └─→ Failure → Add to offline queue
  │     │     │
  │     │     └─→ Return event_id
  │     │
  │     └─→ Update UI with sent message
  │
  └─→ Sync picks up the event on next poll
```

### Media Upload Flow
```
User picks image
  │
  ├─→ RoomDetailPage.pickImage()
  │     │
  │     ├─→ PhotoViewPicker API
  │     │     │
  │     │     └─→ Read file via fileIo
  │     │
  │     ├─→ MediaManager.uploadMedia()
  │     │     │
  │     │     ├─→ MediaHttpClient.upload()
  │     │     │     │
  │     │     │     └─→ POST /media/v3/upload
  │     │     │
  │     │     └─→ Return mxc:// URI
  │     │
  │     └─→ MessageManager.sendMessage()
  │           │
  │           └─→ Send m.image event with mxc:// URL
  │
  └─→ Sync picks up the message
```

---

## Navigation Architecture

### Entry Point
```typescript
// ToonaAbility.ets
windowStage.loadContent('pages/LoginPage')
```

### Navigation System
Uses `NavPathStack` / `NavDestination` (NOT `@ohos.router`).

**Two @Entry containers:**
1. `LoginPage` — Root navigation, owns the primary NavPathStack
2. `RegisterPage` — Also @Entry with NavDestination

**Child pages (no @Entry):**
- Receive `pathStack` via `@Prop`
- Wrap content in `NavDestination()`
- Use `pushPathByName()` for forward navigation

### Navigation Patterns
```typescript
// Forward navigation
this.pathStack.pushPathByName('PageName', param);

// Replace current container (Login → Main)
this.pathStack.clear();
this.pathStack.pushPathByName('MainPage', undefined);

// Back navigation
this.pathStack.pop();
```

---

## Singleton Pattern

Most services use singleton pattern for global access:

```typescript
class ServiceManager {
  private static instance: ServiceManager;
  
  static getInstance(): ServiceManager {
    if (!ServiceManager.instance) {
      ServiceManager.instance = new ServiceManager();
    }
    return ServiceManager.instance;
  }
}
```

**Singleton services:** AuthManager, SyncManager, RoomManager, MessageManager, MediaManager, UserManager, PresenceManager, DeviceManager, PushManager, RoomTagManager, ThemeManager

---

## Theme System

**File:** `utils/ThemeManager.ets`

Singleton theme manager with 20+ color tokens supporting light/dark modes:

```typescript
interface ThemeColors {
  bg: string;
  bgSoft: string;
  surface: string;
  primary: string;
  onPrimary: string;
  text: string;
  textSecondary: string;
  textMute: string;
  divider: string;
  error: string;
  success: string;
  warning: string;
  // ... and more
}
```

**Usage:**
```typescript
import { getThemeColors } from '../utils/ThemeManager';

// In build()
Column() {
  Text('Hello')
    .fontColor(getThemeColors().text)
}
.backgroundColor(getThemeColors().bg)
```

---

## Database Schema

### MessageEntity
| Field | Type | Description |
|-------|------|-------------|
| eventId | string | Primary key |
| roomId | string | Room ID |
| sender | string | Sender MXID |
| type | string | Event type (m.text, m.image, etc.) |
| content | object | Message content (JSON) |
| timestamp | number | Event timestamp |
| status | string | Sending/sent/failed |

### RoomEntity
| Field | Type | Description |
|-------|------|-------------|
| id | string | Primary key (room ID) |
| name | string | Room display name |
| topic | string | Room topic |
| avatarUrl | string | Room avatar MXC URI |
| isSpace | boolean | Whether room is a space |
| unreadCount | number | Unread message count |
| lastEventTime | number | Timestamp of last event |
| tags | object | Room tags (JSON) |

### UserEntity
| Field | Type | Description |
|-------|------|-------------|
| userId | string | Primary key |
| displayName | string | Display name |
| avatarUrl | string | Avatar MXC URI |
| presence | string | Online/offline/unavailable |

### RoomMemberEntity
| Field | Type | Description |
|-------|------|-------------|
| roomId | string | Composite key part 1 |
| userId | string | Composite key part 2 |
| displayName | string | Member display name |
| avatarUrl | string | Member avatar |
| membership | string | join/invite/leave/ban |

---

## Build Configuration

- **Module:** `toona`
- **Strict Mode:** Enabled (`caseSensitiveCheck`, `useNormalizedOHMUrl`)
- **Entry:** `ToonaAbility` (mainElement)
- **Permissions:** INTERNET

---

## Key Design Decisions

1. **NavPathStack over @ohos.router** — More reliable navigation with typed parameters
2. **Singleton services** — Global state management without complex DI
3. **EventProcessor** — Central event routing for sync events
4. **Offline queue** — Messages queued when offline, sent when connection restored
5. **Theme tokens** — All colors flow through ThemeManager for consistency
6. **Entity/Model separation** — Database entities mapped to domain models for clean architecture
