# Toona Matrix Client — Completeness Report

**Date:** 2026-07-07  
**Project:** Toona (HarmonyOS Matrix Client)  
**Spec Coverage:** ~35-40% of Matrix Client-Server API

---

## Executive Summary

Toona is a functional Matrix client for HarmonyOS capable of basic unencrypted messaging. The codebase contains **23 service managers**, **11 network clients**, **11 UI pages**, and **6 chat components**. The backend API plumbing is extensive (covering sync, rooms, messages, media, presence, devices, push rules, and crypto key endpoints), but the client lacks critical features for real-world use: **E2EE decryption**, **push notification delivery**, **SSO authentication**, **threads**, and **reactions**.

**Verdict:** Functional prototype for basic chat on a trusted homeserver. Not production-ready for encrypted or federated use.

---

## Backend Services (23 Managers)

| # | Manager | File | Status | Description |
|---|---------|------|--------|-------------|
| 1 | AuthManager | `services/AuthManager.ets` | ✅ Functional | Password login, registration, logout, session persistence via SPHelper, token validation via `/account/whoami` |
| 2 | SyncManager | `services/SyncManager.ets` | ✅ Functional | Long-poll sync loop, processes joined/invited/left rooms, presence events, account data, to-device events |
| 3 | RoomManager | `services/RoomManager.ets` | ✅ Functional | Create/join/leave rooms, invite/kick/ban/unban users, get members/messages, room state, spaces (create/add children/remove children), typing indicators, read receipts |
| 4 | MessageManager | `services/MessageManager.ets` | ✅ Functional | Send text/emote/notice, reply (m.in_reply_to), edit (m.replace), delete (redact), offline message queue |
| 5 | MediaManager | `services/MediaManager.ets` | ✅ Functional | Upload image/audio/video/file, download via mxc URI, thumbnails, URL preview, media config |
| 6 | UserManager | `services/UserManager.ets` | ✅ Functional | Get/set display name, get/set avatar URL, aggregate profile |
| 7 | PresenceManager | `services/PresenceManager.ets` | ✅ Functional | Get/set presence (online/offline/unavailable), status messages, presence list |
| 8 | DeviceManager | `services/DeviceManager.ets` | ✅ Functional | List/get/update/delete devices, batch delete, rename |
| 9 | PushManager | `services/PushManager.ets` | ⚠️ Partial | Push rules CRUD, enable/disable, mute/unmute rooms, notifications endpoint. **Missing:** device push token registration |
| 10 | RoomStateManager | `services/RoomStateManager.ets` | ✅ Functional | Room avatar, canonical alias, room aliases, members with pagination, read markers, room directory |
| 11 | RoomTagManager | `services/RoomTagManager.ets` | ✅ Functional | Add/remove favourite and low-priority tags, check tag status |
| 12 | EventProcessor | `services/EventProcessor.ets` | ✅ Functional | Processes 8+ event types: message, member, room name/topic/avatar, redaction, encrypted, sticker, presence |
| 13 | FilterManager | `services/FilterManager.ets` | ✅ Functional | Create and retrieve sync filters |
| 14 | ShareManager | `services/ShareManager.ets` | ✅ Functional | Share text, room links, messages, user IDs via HarmonyOS Want intents |
| 15 | ThirdpartyManager | `services/ThirdpartyManager.ets` | ✅ Functional | Thirdparty protocol listing, user/location search and discovery |
| 16 | OpenIdManager | `services/OpenIdManager.ets` | ✅ Functional | OpenID token exchange |
| 17 | VoIPManager | `services/VoIPManager.ets` | ⚠️ Partial | TURN server credential fetching only. **Missing:** WebRTC, call events, call UI |
| 18 | ScanManager | `services/ScanManager.ets` | ✅ Functional | QR barcode scanning via ScanKit, matrix.to link parsing |
| 19 | CryptoManager | `services/CryptoManager.ets` | ⚠️ API-only | Key management APIs (query/upload/claim/sign/backup). **Missing:** actual Olm/Megolm operations |
| 20 | UserAuthManager | `services/UserAuthManager.ets` | ❌ Stub | Biometric auth methods all return `false` |
| 21 | DeviceSecurityManager | `services/DeviceSecurityManager.ets` | ⚠️ Partial | Message security analysis works (Chinese-language regex). Hardware security chip detection stubbed |
| 22 | ServiceCollaborationManager | `services/ServiceCollaborationManager.ets` | ❌ Stub | Every method returns `false` or empty array |
| 23 | MediaLibraryManager | `services/MediaLibraryManager.ets` | ⚠️ Partial | File I/O via CoreFileKit works. Photo picker stubbed |

---

## Network Clients (11 Clients)

All clients extend `BaseHttpClient` which wraps `@ohos.net.http` with Bearer token injection and JSON serialization.

| Client | File | Key Endpoints | Status |
|--------|------|---------------|--------|
| BaseHttpClient | `network/clients/BaseHttpClient.ets` | All HTTP verbs, media upload, UIA 401 detection | ✅ |
| MediaHttpClient | `network/clients/MediaHttpClient.ets` | Upload, download, thumbnail, preview_url, config | ✅ |
| RoomHttpClient | `network/clients/RoomHttpClient.ets` | Room state, members, read markers, receipts, directory | ✅ |
| MessageHttpClient | `network/clients/MessageHttpClient.ets` | Typing, relations, annotations, receipts | ✅ |
| UserHttpClient | `network/clients/UserHttpClient.ets` | Profile, push rules, notifications, room tags | ✅ |
| DeviceHttpClient | `network/clients/DeviceHttpClient.ets` | Device CRUD, crypto key endpoints | ✅ |
| PresenceHttpClient | `network/clients/PresenceHttpClient.ets` | Presence status, list | ✅ |
| FilterHttpClient | `network/clients/FilterHttpClient.ets` | Filter create/get | ✅ |
| ThirdpartyHttpClient | `network/clients/ThirdpartyHttpClient.ets` | Protocol/user/location discovery | ✅ |
| OpenIdHttpClient | `network/clients/OpenIdHttpClient.ets` | OpenID token exchange | ✅ |
| VoipHttpClient | `network/clients/VoipHttpClient.ets` | TURN server credentials | ✅ |

---

## Matrix API Coverage

### Implemented Endpoints

| Spec Section | Endpoint | Method | Status |
|--------------|----------|--------|--------|
| **Discovery** | `/.well-known/matrix/client` | GET | ✅ |
| **Discovery** | `/_matrix/client/versions` | GET | ✅ |
| **Auth** | `/_matrix/client/v3/login` | POST | ✅ |
| **Auth** | `/_matrix/client/v3/register` | POST | ✅ |
| **Auth** | `/_matrix/client/v3/logout` | POST | ✅ |
| **Auth** | `/_matrix/client/v3/account/whoami` | GET | ✅ |
| **Sync** | `/_matrix/client/v3/sync` | GET | ✅ |
| **Rooms** | `/_matrix/client/v3/createRoom` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/join` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/leave` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/invite` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/kick` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/ban` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/unban` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/forget` | POST | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/messages` | GET | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/state` | GET | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/state/{type}` | PUT | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/send/{type}/{txnId}` | PUT | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/joined_members` | GET | ✅ |
| **Rooms** | `/_matrix/client/v3/rooms/{roomId}/members` | GET | ✅ |
| **Rooms** | `/_matrix/client/v3/joined_rooms` | GET | ✅ |
| **Room Aliases** | `/_matrix/client/v3/directory/room/{alias}` | GET/PUT/DELETE | ✅ |
| **Room Directory** | `/_matrix/client/v3/publicRooms` | GET/POST | ✅ |
| **Typing** | `/_matrix/client/v3/rooms/{roomId}/typing/{userId}` | PUT/GET | ✅ |
| **Receipts** | `/_matrix/client/v3/rooms/{roomId}/receipt/{receiptType}/{eventId}` | POST | ✅ |
| **Read Markers** | `/_matrix/client/v3/rooms/{roomId}/read_markers` | POST | ✅ |
| **Relations** | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}` | GET | ✅ |
| **Relations** | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}/{relType}/{type}` | PUT | ✅ |
| **Presence** | `/_matrix/client/v3/presence/{userId}/status` | GET/PUT | ✅ |
| **Presence** | `/_matrix/client/v3/presence/list` | POST | ✅ |
| **Profile** | `/_matrix/client/v3/profile/{userId}/displayname` | GET/PUT | ✅ |
| **Profile** | `/_matrix/client/v3/profile/{userId}/avatar_url` | GET/PUT | ✅ |
| **Push** | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | GET/PUT/DELETE | ✅ |
| **Push** | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}/actions` | PUT | ✅ |
| **Notifications** | `/_matrix/client/v3/notifications` | GET/POST | ✅ |
| **Tags** | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` | GET/PUT/DELETE | ✅ |
| **Devices** | `/_matrix/client/v3/devices/{deviceId}` | GET/PUT/DELETE | ✅ |
| **Devices** | `/_matrix/client/v3/delete_devices` | POST | ✅ |
| **Crypto** | `/_matrix/client/v3/keys/query` | POST | ✅ |
| **Crypto** | `/_matrix/client/v3/keys/upload` | POST | ✅ |
| **Crypto** | `/_matrix/client/v3/keys/claim` | POST | ✅ |
| **Crypto** | `/_matrix/client/v3/keys/signatures/upload` | POST | ✅ |
| **Key Backup** | `/_matrix/client/v3/room_keys/version` | GET/POST | ✅ |
| **Key Backup** | `/_matrix/client/v3/room_keys/version/{version}` | GET/PUT/DELETE | ✅ |
| **Key Backup** | `/_matrix/client/v3/room_keys/keys` | GET/PUT/POST | ✅ |
| **Media** | `/_matrix/media/v3/upload` | POST | ✅ |
| **Media** | `/_matrix/media/v3/download/{serverName}/{mediaId}` | GET | ✅ |
| **Media** | `/_matrix/media/v3/thumbnail/{serverName}/{mediaId}` | GET | ✅ |
| **Media** | `/_matrix/media/v3/preview_url` | GET | ✅ |
| **Media** | `/_matrix/media/v3/config` | GET | ✅ |
| **Filter** | `/_matrix/client/v3/user/{userId}/filter` | POST | ✅ |
| **Filter** | `/_matrix/client/v3/user/{userId}/filter/{filterId}` | GET | ✅ |
| **Thirdparty** | `/_matrix/client/v3/thirdparty/protocols` | GET | ✅ |
| **Thirdparty** | `/_matrix/client/v3/thirdparty/protocol/{protocol}` | GET | ✅ |
| **Thirdparty** | `/_matrix/client/v3/thirdparty/user/{protocol}` | GET/POST | ✅ |
| **Thirdparty** | `/_matrix/client/v3/thirdparty/location/{protocol}` | GET/POST | ✅ |
| **OpenID** | `/_matrix/client/v3/user/{userId}/openid` | POST | ✅ |
| **VoIP** | `/_matrix/client/v3/voip/turnServer` | GET | ✅ |
| **Spaces** | `/_matrix/client/v1/rooms/{roomId}/spaces` | GET | ✅ |

### Missing Endpoints (not implemented)

| Spec Section | Endpoint | Priority |
|--------------|----------|----------|
| **Auth** | `/_matrix/client/v3/login/sso/redirect` | High |
| **Auth** | `/_matrix/client/v3/account/password` | Medium |
| **Auth** | `/_matrix/client/v3/account/deactivate` | Medium |
| **Search** | `/_matrix/client/v3/search` | High |
| **Threads** | `/_matrix/client/v3/rooms/{roomId}/threads` | High |
| **Hierarchy** | `/_matrix/client/v1/rooms/{roomId}/hierarchy` | Medium |
| **Identity** | `/_matrix/identity/v2/lookup` | Medium |
| **Push Gateway** | Huawei Push Kit registration | High |

---

## E2EE / Encryption Status

**API Layer Exists, No Actual Crypto**

| Component | Status | Notes |
|-----------|--------|-------|
| CryptoManager | ✅ API calls | Key query, upload, claim, signature upload, backup |
| DeviceHttpClient | ✅ HTTP calls | `/keys/query`, `/keys/upload`, `/keys/claim`, `/keys/signatures/upload`, `/room_keys/*` |
| DeviceTypes | ✅ Types | Full type definitions for DeviceKeyInfo, QueryKeysRequest/Response, etc. |
| SyncManager | ✅ Receives | Recognizes `m.room.encrypted` events |
| EventProcessor | ✅ Parses | Extracts algorithm, ciphertext, device_id, session_id |
| Olm/Megolm | ❌ Missing | No actual encryption/decryption operations |
| Key Verification | ❌ Missing | No SAS, QR, or emoji verification |
| Cross-signing | ❌ Missing | No cross-signing support |
| Key Import/Export | ❌ Missing | No key export/import |

**Impact:** Encrypted messages are received and stored but **cannot be decrypted**. The client is unusable on encrypted rooms.

---

## Push Notifications Status

| Component | Status | Notes |
|-----------|--------|-------|
| PushManager | ✅ Rules CRUD | Create/delete/enable/disable push rules |
| UserHttpClient | ✅ HTTP | All push rule endpoints wired |
| PushTypes | ✅ Types | PushRule, PushRuleset, PushRuleCondition, NotificationData |
| Device Token Registration | ❌ Missing | No Huawei Push Kit / FCM token registration |
| OS Push Delivery | ❌ Missing | No push notification received from OS |

**Impact:** Users only see messages when the app is open and syncing. No background notifications.

---

## UI Pages (11 Total)

| # | Page | File | Type | Status | Description |
|---|------|------|------|--------|-------------|
| 1 | LoginPage | `pages/LoginPage.ets` | @Entry | ✅ | Homeserver discovery, password login, SSO/biometric stubs, register link |
| 2 | RegisterPage | `pages/RegisterPage.ets` | @Entry | ✅ | Account registration with homeserver, username, password |
| 3 | MainPage | `pages/MainPage.ets` | @Entry | ✅ | Tab shell (Messages/Spaces), filter bar, sync status, navigation hub |
| 4 | RoomListPage | `pages/RoomListPage.ets` | Component | ✅ | Filtered room list (All/Unread/DM/Room/Fav/Invite) with unread badges |
| 5 | RoomDetailPage | `pages/RoomDetailPage.ets` | NavDestination | ✅ | Full chat: text/image/voice, reply, edit, action menu, member panel |
| 6 | SpacePage | `pages/SpacePage.ets` | Component | ✅ | Hierarchical space tree with expand/collapse |
| 7 | SpaceDetailPage | `pages/SpaceDetailPage.ets` | NavDestination | ✅ | Space children list |
| 8 | SearchPage | `pages/SearchPage.ets` | NavDestination | ✅ | Room alias/address search |
| 9 | JoinRoomPage | `pages/JoinRoomPage.ets` | NavDestination | ✅ | Create/join rooms, user directory search, QR scan |
| 10 | JoinSpacePage | `pages/JoinSpacePage.ets` | NavDestination | ✅ | Create/join spaces, public space search |
| 11 | SettingsPage | `pages/SettingsPage.ets` | NavDestination | ✅ | 12 sub-components assembled |

### Navigation Architecture

```
ToonaAbility (loadContent)
  └─ LoginPage (@Entry, Navigation root)
       ├─ RegisterPage (pushPathByName)
       └─ MainPage (pushPathByName, replaces LoginPage via clear+push)
            ├─ Tab 0: RoomListPage (embedded @Component)
            │    └─ RoomDetailPage (pushPathByName)
            │         └─ MemberListPanel (overlay)
            │         └─ MessageActionMenu (overlay)
            ├─ Tab 1: SpacePage (embedded @Component)
            │    ├─ SpaceDetailPage (pushPathByName)
            │    │    └─ RoomDetailPage (pushPathByName)
            │    └─ JoinSpacePage (pushPathByName)
            ├─ SearchPage (pushPathByName)
            │    └─ RoomDetailPage (pushPathByName)
            ├─ JoinRoomPage (pushPathByName via FAB)
            │    └─ RoomDetailPage (pushPathByName)
            ├─ JoinSpacePage (pushPathByName via FAB)
            └─ SettingsPage (pushPathByName via user avatar click)
```

---

## Chat Components (6)

| Component | File | Status | Description |
|-----------|------|--------|-------------|
| MessageBubble | `components/MessageBubble.ets` | ✅ | Text, image, file, voice messages with waveform animation |
| MessageInputBar | `components/MessageInputBar.ets` | ✅ | Text input, voice/image pick buttons |
| EditMessage | `components/EditMessage.ets` | ✅ | Inline message editing with save/cancel |
| ReplyQuote | `components/ReplyQuote.ets` | ✅ | Reply context display with sender name |
| MessageActionMenu | `components/MessageActionMenu.ets` | ✅ | Reply/copy/delete/edit/share/security check |
| MemberListPanel | `components/MemberListPanel.ets` | ✅ | Member list with presence indicators |

### Message Types

| Type | Send | Receive | Notes |
|------|------|---------|-------|
| m.text | ✅ | ✅ | Full support |
| m.emote | ✅ | ❌ | Send only |
| m.notice | ✅ | ❌ | Send only |
| m.image | ✅ | ✅ | Thumbnail display, no fullscreen viewer |
| m.file | ✅ | ✅ | Display only, no download/preview |
| m.audio | ✅ | ✅ | Full voice recording + playback with animation |
| m.sticker | ❌ | ✅ | Received but no send UI |
| m.video | ❌ | ❌ | Not implemented |
| m.location | ❌ | ❌ | Not implemented |
| m.reaction | ❌ | ❌ | Not implemented |
| m.room.encrypted | ❌ | ✅ | Received but cannot decrypt |

---

## Settings Components (12)

| # | Component | File | Status | Description |
|---|-----------|------|--------|-------------|
| 1 | SettingsHeader | `settings/SettingsHeader.ets` | ✅ | Title bar with divider |
| 2 | UserProfileCard | `settings/UserProfileCard.ets` | ✅ | Avatar, name editing, presence indicator |
| 3 | ThemeSettings | `settings/ThemeSettings.ets` | ✅ | Light/dark/system theme picker |
| 4 | PresenceSettings | `settings/PresenceSettings.ets` | ✅ | Online/offline/unavailable selector + status message |
| 5 | RoomTagsSettings | `settings/RoomTagsSettings.ets` | ✅ | Favorite/low-priority room management |
| 6 | DeviceManagement | `settings/DeviceManagement.ets` | ✅ | Device list with current device badge and delete |
| 7 | LogoutButton | `settings/LogoutButton.ets` | ✅ | Logout action |
| 8 | SecuritySettings | `settings/SecuritySettings.ets` | ⚠️ | AI security check works, fraud tip display-only |
| 9 | BiometricSettings | `settings/BiometricSettings.ets` | ⚠️ | Toggle works, verify calls stub |
| 10 | CollaborationSettings | `settings/CollaborationSettings.ets` | ❌ | Device handoff stub |
| 11 | QRScannerSettings | `settings/QRScannerSettings.ets` | ✅ | QR scanning functional |
| 12 | AboutSection | `settings/AboutSection.ets` | ❌ | Links show "开发中" toasts |

---

## Database Architecture

- **ORM:** `@mlethe/room` (HarmonyOS ORM)
- **Schema:** `ToonaDatabase.ets`
- **Entities:** MessageEntity, RoomEntity, UserEntity, RoomMemberEntity
- **DAOs:** MessageDao, RoomDao, UserDao, RoomMemberDao
- **Converters:** ContentConverter (JSON serialization), TagsConverter (tag map persistence)
- **Facade:** LocalDatabase.ets (513 lines) with bidirectional entity/model mapping

---

## Design System

- **ThemeManager:** Singleton with 20+ color tokens (light/dark modes)
- **Primary:** `#3ecf8e` (emerald green)
- **On-primary:** `#171717` (near-black, not white)
- **Border radius scale:** xs(4), sm(6), md(8), lg(12), xl(16), full(9999)
- **Typography:** Weight 500 for display, 400 for body
- **All hardcoded colors replaced with theme tokens**

---

## Overall Completeness Estimate

| Area | Maturity | Notes |
|------|----------|-------|
| Core messaging (send/receive text) | ~85% | Works for unencrypted rooms |
| Room management | ~80% | Create, join, leave, invite, kick, ban |
| Spaces | ~70% | Create, add/remove children, view hierarchy |
| Media handling | ~65% | Upload/download/thumbnail work, picker stubbed |
| User profiles | ~60% | Display name and avatar, no password/email |
| Device management | ~70% | Full CRUD, crypto key endpoints |
| Push notifications | ~40% | Rules management only, no delivery |
| Authentication | ~50% | Password login works, no SSO/OAuth/UIA |
| Encryption (E2EE) | ~15% | API plumbing only, no actual crypto |
| Voice/video calling | ~10% | TURN credentials only |
| **Overall Matrix spec coverage** | **~35-40%** | Functional prototype |

---

## Conclusion

Toona is a well-structured HarmonyOS Matrix client with solid backend plumbing and a functional UI for basic messaging. The codebase demonstrates good architecture (MVVM + Repository, singleton services, DAO pattern) and covers a significant portion of the Matrix CS API at the HTTP level. However, the critical gaps in E2EE decryption, push notification delivery, and several key UI features (threads, reactions, image viewer, room settings) prevent it from being a production-ready client. The next priorities should be:

1. **E2EE decryption** (Olm/Megolm library integration)
2. **Push notification delivery** (Huawei Push Kit)
3. **Image viewer** (fullscreen, zoom, gallery)
4. **Room settings page** (name, topic, members, permissions)
5. **Thread view** (threaded conversations)
6. **Reaction picker** (emoji reactions)
