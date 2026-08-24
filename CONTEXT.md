# Toona Domain Glossary

## Core Domain

- **Room** — A Matrix room (chat or space). Parsed from sync data, stored locally.
- **Message** — A single event in a room timeline. Has type, sender, content, status.
- **Session** — Authenticated state: homeserver URL, access token, user ID, device ID.

## Message Operations

- **MessageSender** — Deep module that owns content construction and HTTP dispatch for *new* messages. Interface: `IMessageSender` with `sendText`, `sendSticker`, `sendMedia`, `editMessage`. Hides Matrix content format, txnId generation, and URL encoding from callers.
- **MessageManager** — Module for non-send message operations: delete (redact), forward, message reads (from LocalDatabase), offline queue. No content construction.
- **MediaActionHandler** — Orchestrates file picking, upload (via MediaManager), and message dispatch (via MessageSender) for media messages. Interface: `IMediaActionHandler`.
- **RoomMetadataLoader** — Loads room metadata: member presences, typing users, room topic/name, and manages typing notifications. Interface: `IRoomMetadataLoader`.

## Navigation

- **NavPathStack** — Navigation container. All page transitions use `pushPathByName`.
- **LoginPage** — Entry container. Replaced by MainPage after login.
- **MainPage** — Main shell with tabs.
- **Child pages** — Receive `pathStack` via `@Prop`, no `@Entry`, no `NavDestination`.

## Platform Adapters

- **IFilePicker** / **IClipboard** / **IAudioRecorder** — Seam interfaces for HarmonyOS platform APIs. Prod adapters: `HarmonyFilePicker`, `HarmonyClipboard`, `HarmonyAudioRecorder`. Registered in ServiceLocator; injected into ViewModels via deps structs.

## Service Interfaces

Every service that a ViewModel depends on has an `IXxx` interface. Concrete class `implements IXxx`. ServiceLocator getters return the interface type; setters accept the concrete class.

| Interface | Implementation | Used by ViewModels |
|-----------|---------------|-------------------|
| `IAuthManager` | `AuthManager` | Main, Login, Register, RoomDetail, JoinRoom, Settings |
| `IRoomManager` | `RoomManager` | Main, RoomDetail, Search, MessageSearch, InviteManagement, Space, SpaceDetail, JoinRoom, Settings, RoomSettings |
| `ISyncManager` | `SyncManager` | Main, RoomDetail |
| `IMessageSender` | `MessageSender` | RoomDetail |
| `IMessageManager` | `MessageManager` | RoomDetail, MessageSearch |
| `IMediaManager` | `MediaManager` | Settings |
| `IUserManager` | `UserManager` | Main, UserProfile, Settings |
| `IRoomTagManager` | `RoomTagManager` | Main, Settings |
| `IDeviceManager` | `DeviceManager` | Settings |
| `IPushManager` | `PushManager` | NotificationSettings |
| `IVerificationService` | `VerificationService` | — (used by MessageBubble, not ViewModel) |
| `IShareManager` | `ShareManager` | RoomDetail |
| `IDeviceSecurityManager` | `DeviceSecurityManager` | — (page-level, not in ViewModel deps) |
| `IScanManager` | `ScanManager` | JoinRoom (via deps), Settings (page-level callback) |
| `IMediaActionHandler` | `MediaActionHandler` | RoomDetail |
| `IRoomMetadataLoader` | `RoomMetadataLoader` | RoomDetail |

## ViewModel Dependency Injection

ViewModels accept dependencies via constructor. ViewModels with >4 deps use a deps struct (`XxxDeps` interface). ViewModels with ≤2 deps use individual params. Pages build deps from `ServiceLocator` calls.

| ViewModel | Pattern | Deps struct |
|-----------|---------|-------------|
| `RoomDetailViewModel` | Deps struct | `RoomDetailDeps` (7 fields) + userId/homeserver strings + onCopyMessage callback |
| `MainViewModel` | Deps struct | `MainDeps` (5 fields) |
| `JoinRoomViewModel` | Deps struct | `JoinRoomDeps` (3 fields) |
| `SettingsViewModel` | Deps struct | `SettingsDeps` (8 fields) + 5 callbacks (deviceSecurity, scan, biometricToggle, biometricVerify, collaboration) |
| `RoomSettingsViewModel` | Individual params | — (1 dep: IRoomManager) |
| `NotificationSettingsViewModel` | Individual params | — (1 dep: IPushManager) |
| `LoginViewModel` | Individual params | — (1 dep: IAuthManager) |
| `RegisterViewModel` | Individual params | — (1 dep: IAuthManager) |
| `SearchViewModel` | Individual params | — (1 dep: IRoomManager) |
| `MessageSearchViewModel` | Individual params | — (2 deps: IRoomManager, IMessageManager) |
| `UserProfileViewModel` | Individual params | userId string + 1 dep: IUserManager |
| `InviteManagementViewModel` | Individual params | — (1 dep: IRoomManager) |
| `SpaceViewModel` | Individual params | — (1 dep: IRoomManager) |
| `SpaceDetailViewModel` | Individual params | spaceId/spaceName strings + 1 dep: IRoomManager) |

## Architecture Decisions

- Deep modules over shallow wrappers. Interface seams at every dependency a ViewModel uses.
- `IMessageSender` seam: two adapters justify it (prod `MessageSender` + test fake).
- `IMediaActionHandler` and `IRoomMetadataLoader` seams: pre-built externally by the page, injected as deps. Two adapters justify each seam (prod + test fake).
- ViewModels accept dependencies via constructor, not static `ServiceLocator` access.
- Value params (userId, homeserver) and callbacks (onCopyMessage, onLeaveRoom, onStateChanged) are separate from deps struct — deps struct is purely service seams.
- Platform and hardware-bound deps (IDeviceSecurityManager, IScanManager) live at page level, injected into ViewModels via callbacks. Same pattern as RoomDetailPage with deviceSecurityManager.
- Stub-only services (UserAuthManager, ServiceCollaborationManager) are deleted; their behavior moves to page-level callback implementations that show Toast.
- Pages get platform deps (IMediaManager, IVerificationService) directly from ServiceLocator for child components, not through ViewModel getters.
- ServiceLocator getters return interface types; pages build deps structs from ServiceLocator.
