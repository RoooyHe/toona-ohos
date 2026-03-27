# Matrix Client-Server API v3 Documentation

> Toona Matrix Client for HarmonyOS - API Implementation Status

## Overview

This document lists all Matrix Client-Server API endpoints as defined in the [Matrix specification](https://matrix.org/docs/api/client-server/). Each endpoint is marked as **Implemented** or **Not Implemented**.

---

## API Versions

| Version | Status | Description |
|---------|--------|-------------|
| `/_matrix/client/v3/` | Current | Primary API version |
| `/_matrix/client/r0/` | Supported | Rack-compatible version |
| `/_matrix/client/v1/` | Partial | Legacy, used for some Space APIs |
| `/_matrix/client/versions` | ✅ Implemented | Server version discovery |

---

## Authentication

### Login
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/login` | ✅ Implemented |
| POST | `/_matrix/client/r0/login` | ✅ Implemented |

### Register
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/register` | ✅ Implemented |
| POST | `/_matrix/client/r0/register` | ✅ Implemented |

### Logout
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/logout` | ✅ Implemented |
| POST | `/_matrix/client/v3/logout/all` | ❌ Not Implemented |

### WhoAmI
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/account/whoami` | ✅ Implemented |

### Token Management
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/account/deactivate` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/account/password` | ❌ Not Implemented |

---

## Room Management

### Create Room
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/createRoom` | ✅ Implemented |

### Join Room
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/rooms/{roomId}/join` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/join` | ✅ Implemented |
| POST | `/_matrix/client/v3/join/{roomIdOrAlias}` | ✅ Implemented |
| POST | `/_matrix/client/v3/rooms/{roomId}/leave` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/leave` | ✅ Implemented |

### Room Membership
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/rooms/{roomId}/invite` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/invite` | ✅ Implemented |
| POST | `/_matrix/client/v3/rooms/{roomId}/kick` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/kick` | ✅ Implemented |
| POST | `/_matrix/client/v3/rooms/{roomId}/ban` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/ban` | ✅ Implemented |
| POST | `/_matrix/client/v3/rooms/{roomId}/unban` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/unban` | ✅ Implemented |
| POST | `/_matrix/client/v3/rooms/{roomId}/forget` | ✅ Implemented |
| POST | `/_matrix/client/r0/rooms/{roomId}/forget` | ✅ Implemented |

### Room Members
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/joined_members` | ✅ Implemented |
| GET | `/_matrix/client/r0/rooms/{roomId}/joined_members` | ✅ Implemented |
| GET | `/_matrix/client/v3/rooms/{roomId}/members` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/rooms/{roomId}/state` | ❌ Not Implemented |

### Joined Rooms
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/joined_rooms` | ✅ Implemented |
| GET | `/_matrix/client/r0/joined_rooms` | ✅ Implemented |

---

## Room State

### Get/Set Room State
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/{eventType}` | ✅ Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/{eventType}/{stateKey}` | ✅ Implemented |

### Room Name
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | ✅ Implemented |

### Room Topic
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | ✅ Implemented |

### Room Avatar
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.avatar` | ❌ Not Implemented |

### Canonical Alias
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/canonical_alias` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.canonical_alias` | ❌ Not Implemented |

### Room Aliases
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/aliases` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.aliases` | ❌ Not Implemented |

---

## Room Discovery

### Resolve Alias
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/directory/room/{roomAlias}` | ✅ Implemented |
| PUT | `/_matrix/client/v3/directory/room/{roomAlias}` | ❌ Not Implemented |
| DELETE | `/_matrix/client/v3/directory/room/{roomAlias}` | ❌ Not Implemented |

### Room Directory
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/publicRooms` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/publicRooms` | ❌ Not Implemented |
| GET | `/_matrix/client/r0/publicRooms` | ❌ Not Implemented |
| POST | `/_matrix/client/r0/publicRooms` | ❌ Not Implemented |

---

## Messaging

### Send Message
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/{eventType}/{txnId}` | ✅ Implemented |
| PUT | `/_matrix/client/r0/rooms/{roomId}/send/{eventType}/{txnId}` | ✅ Implemented |

### Message Types
| Event Type | Status |
|------------|--------|
| `m.room.message` | ✅ Implemented |
| `m.room.emote` | ✅ Implemented |
| `m.room.notice` | ✅ Implemented |
| `m.sticker` | ❌ Not Implemented |

### Get Messages
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/rooms/{roomId}/messages` | ✅ Implemented |
| GET | `/_matrix/client/r0/rooms/{roomId}/messages` | ✅ Implemented |

### Redact Messages
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/redact/{eventId}/{txnId}` | ✅ Implemented |
| PUT | `/_matrix/client/r0/rooms/{roomId}/redact/{eventId}/{txnId}` | ✅ Implemented |

### Message Reactions
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}/m.annotation` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}` | ❌ Not Implemented |

### Edit Messages
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}` | ✅ Implemented |

### Reply Messages
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}` | ✅ Implemented |

### Read Markers
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/rooms/{roomId}/read_markers` | ❌ Not Implemented |

### Typing
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/typing/{userId}` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/rooms/{roomId}/typing/{userId}` | ❌ Not Implemented |

### Receipts
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/rooms/{roomId}/receipt/{receiptType}/{eventId}` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/rooms/{roomId}/receipt/{receiptType}/{eventId}` | ❌ Not Implemented |

---

## Sync

### Sync
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/sync` | ✅ Implemented |
| GET | `/_matrix/client/r0/sync` | ✅ Implemented |

### Initial Sync (Deprecated)
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/initialSync` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/conInitialSync` | ❌ Not Implemented |

---

## Spaces

### Create Space
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/createRoom` (with `type: m.space`) | ✅ Implemented |

### Get Space Children
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v1/rooms/{roomId}/spaces` | ✅ Implemented |

### Add Child to Space
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | ✅ Implemented |

### Remove Child from Space
| Method | Endpoint | Status |
|--------|----------|--------|
| DELETE | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | ✅ Implemented |

### Get Space Hierarchy
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v1/rooms/{roomId}/spaces` | ✅ Implemented |

---

## User Directory

### Search Users
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/user_directory/search` | ✅ Implemented |
| GET | `/_matrix/client/v3/user_directory/search` | ✅ Implemented |

### Profile
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/profile/{userId}` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/profile/{userId}` | ❌ Not Implemented |

### Display Name
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/profile/{userId}/displayname` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/profile/{userId}/displayname` | ❌ Not Implemented |

### Avatar URL
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/profile/{userId}/avatar_url` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/profile/{userId}/avatar_url` | ❌ Not Implemented |

---

## Content Repository (Media)

### Upload
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/media/v3/upload` | ❌ Not Implemented |
| POST | `/_matrix/media/r0/upload` | ❌ Not Implemented |

### Download
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/media/v3/download/{serverName}/{mediaId}` | ❌ Not Implemented |
| GET | `/_matrix/media/r0/download/{serverName}/{mediaId}` | ❌ Not Implemented |

### Thumbnail
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/media/v3/thumbnail/{serverName}/{mediaId}` | ❌ Not Implemented |
| GET | `/_matrix/media/r0/thumbnail/{serverName}/{mediaId}` | ❌ Not Implemented |

### Preview URL
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/media/v3/preview_url` | ❌ Not Implemented |

### Config
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/media/v3/config` | ❌ Not Implemented |

---

## Devices

### List Devices
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/devices` | ❌ Not Implemented |
| GET | `/_matrix/client/r0/devices` | ❌ Not Implemented |

### Get Device
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/devices/{deviceId}` | ❌ Not Implemented |

### Update Device
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/devices/{deviceId}` | ❌ Not Implemented |

### Delete Device
| Method | Endpoint | Status |
|--------|----------|--------|
| DELETE | `/_matrix/client/v3/devices/{deviceId}` | ❌ Not Implemented |

### Delete Devices
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/delete_devices` | ❌ Not Implemented |

---

## End-to-End Encryption

### Query Keys
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/keys/query` | ❌ Not Implemented |
| POST | `/_matrix/client/r0/keys/query` | ❌ Not Implemented |

### Upload Keys
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/keys/upload` | ❌ Not Implemented |
| POST | `/_matrix/client/r0/keys/upload` | ❌ Not Implemented |

### Claim Keys
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/keys/claim` | ❌ Not Implemented |
| POST | `/_matrix/client/r0/keys/claim` | ❌ Not Implemented |

### Room Keys
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/room/keys/query` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/room/keys/upload` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/room/keys/keys` | ❌ Not Implemented |

### Key Backup
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/room_keys/version` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/room_keys/version` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/room_keys/version` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/room_keys/keys/{roomId}/{sessionId}` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/room_keys/keys/{roomId}/{sessionId}` | ❌ Not Implemented |

### Signature
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/keys/signatures/upload` | ❌ Not Implemented |

---

## Room Tags

### Get Tags
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags` | ❌ Not Implemented |

### Add Tag
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` | ❌ Not Implemented |

### Remove Tag
| Method | Endpoint | Status |
|--------|----------|--------|
| DELETE | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` | ❌ Not Implemented |

---

## Push Notifications

### Push Rules
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/pushrules` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ Not Implemented |
| PUT | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ Not Implemented |
| DELETE | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ Not Implemented |

### Push Rule Actions
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}/actions` | ❌ Not Implemented |

### Notifications
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/notifications` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/notifications` | ❌ Not Implemented |

---

## Filtering

### Create Filter
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/user/{userId}/filter` | ❌ Not Implemented |
| POST | `/_matrix/client/r0/user/{userId}/filter` | ❌ Not Implemented |

### Get Filter
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/user/{userId}/filter/{filterId}` | ❌ Not Implemented |
| GET | `/_matrix/client/r0/user/{userId}/filter/{filterId}` | ❌ Not Implemented |

---

## Presence

### Get Presence
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/presence/{userId}/status` | ❌ Not Implemented |

### Set Presence
| Method | Endpoint | Status |
|--------|----------|--------|
| PUT | `/_matrix/client/v3/presence/{userId}/status` | ❌ Not Implemented |

### List Presence
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/presence/list` | ❌ Not Implemented |

---

## Thirdparty

### Protocols
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/thirdparty/protocols` | ❌ Not Implemented |
| GET | `/_matrix/client/v3/thirdparty/protocol/{protocol}` | ❌ Not Implemented |

### User Search
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/thirdparty/user/{protocol}` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/thirdparty/user/` | ❌ Not Implemented |

### Location Search
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/thirdparty/location/{protocol}` | ❌ Not Implemented |
| POST | `/_matrix/client/v3/thirdparty/location/` | ❌ Not Implemented |

---

## VoIP

### Turn Server
| Method | Endpoint | Status |
|--------|----------|--------|
| GET | `/_matrix/client/v3/voip/turnServer` | ❌ Not Implemented |

---

## OpenID Connect

### Token
| Method | Endpoint | Status |
|--------|----------|--------|
| POST | `/_matrix/client/v3/user/{userId}/openid` | ❌ Not Implemented |

---

## Summary

| Category | Implemented | Not Implemented | Total |
|----------|-------------|-----------------|-------|
| Authentication | 5 | 2 | 7 |
| Room Management | 14 | 2 | 16 |
| Room State | 2 | 11 | 13 |
| Room Discovery | 1 | 5 | 6 |
| Messaging | 4 | 11 | 15 |
| Sync | 1 | 2 | 3 |
| Spaces | 4 | 0 | 4 |
| User Directory | 1 | 4 | 5 |
| Content Repository | 0 | 6 | 6 |
| Devices | 0 | 5 | 5 |
| E2E Encryption | 0 | 10 | 10 |
| Room Tags | 0 | 3 | 3 |
| Push Notifications | 0 | 6 | 6 |
| Filtering | 0 | 2 | 2 |
| Presence | 0 | 3 | 3 |
| Thirdparty | 0 | 6 | 6 |
| VoIP | 0 | 1 | 1 |
| OpenID | 0 | 1 | 1 |
| **Total** | **32** | **80** | **112** |

**Implementation Progress: 28.6%** (32/112 endpoints)

---

## Priority Features to Implement

1. **High Priority**
   - Content Repository (Media upload/download)
   - Profile management (display name, avatar)
   - Read receipts and typing indicators

2. **Medium Priority**
   - End-to-End Encryption support
   - Push notifications
   - Room tags/favorites

3. **Low Priority**
   - Thirdparty API
   - VoIP support
   - OpenID Connect token exchange
