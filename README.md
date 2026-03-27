# Toona - Matrix Client for HarmonyOS

<p align="center">
  <img src="./AppScope/resources/base/media/1024.jpg" alt="Toona Logo" width="128" height="128" style="border-radius: 24px;">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS-000000?style=flat-square&logo=huawei" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Matrix-v3-green?style=flat-square&logo=matrix" alt="Matrix">
</p>

[中文版](./README_CN.md) | English

A Matrix client application for HarmonyOS (鸿蒙OS), modeled after ElementX/Element Android client architecture.

## Features

- **Authentication** - Login/Register with Matrix homeserver
- **Session Persistence** - Encrypted token storage with automatic session restore
- **Real-time Sync** - Long-polling sync engine for live updates
- **Room Management** - Create, join, leave rooms
- **Messaging** - Send and receive text messages
- **Direct Chats** - Start DM conversations with other users
- **Space Support** - Hierarchical room organization
- **Search** - Search users and rooms

## Screenshots

<!-- Add screenshots here -->

## Architecture

```
toona/src/main/ets/
├── network/           # HTTP client for Matrix API
├── models/            # Data models and Matrix types
├── database/          # SQLite local storage
├── storage/           # SecureStorage for session tokens
├── services/          # Business logic (Auth, Sync, Room, Message)
├── pages/             # UI pages
└── toonaability/      # Application entry point
```

### Tech Stack

- **Framework**: HarmonyOS + ArkTS (strict mode)
- **Architecture**: MVVM + Repository pattern
- **Storage**: SQLite (local) + encrypted preferences (session)
- **Network**: `@kit.NetworkKit` HTTP client

## Getting Started

### Prerequisites

- DevEco Studio (latest version)
- HarmonyOS SDK
- Node.js (for hvigor)

### Build

1. Open project in DevEco Studio
2. Select the `toona` module
3. Click **Build** > **Build Module**
4. Or use command line:
   ```bash
   hvigor build -m toona
   ```

### Build Commands

| Command | Description |
|---------|-------------|
| `hvigor build` | Full build |
| `hvigor clean` | Clean build artifacts |
| `hvigor build -m toona` | Build specific module |
| `hvigor build --mode debug` | Debug build |

## Matrix API

This client implements the [Matrix Client-Server API v3](https://matrix.org/docs/api/client-server/).

### Implemented APIs

#### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/_matrix/client/v3/login` | Login with username/password |
| POST | `/_matrix/client/v3/register` | Register new account |
| POST | `/_matrix/client/v3/logout` | Logout current session |
| GET | `/_matrix/client/v3/account/whoami` | Validate token & get user ID |
| GET | `/_matrix/client/versions` | Check server version |

#### Room Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/_matrix/client/v3/createRoom` | Create room or space |
| POST | `/_matrix/client/v3/rooms/{roomId}/join` | Join room |
| POST | `/_matrix/client/v3/rooms/{roomId}/leave` | Leave room |
| POST | `/_matrix/client/v3/rooms/{roomId}/invite` | Invite user |
| POST | `/_matrix/client/v3/rooms/{roomId}/kick` | Kick user |
| POST | `/_matrix/client/v3/rooms/{roomId}/ban` | Ban user |
| POST | `/_matrix/client/v3/rooms/{roomId}/unban` | Unban user |
| POST | `/_matrix/client/v3/rooms/{roomId}/forget` | Forget room |

#### Room State

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | Set room name |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | Set room topic |
| GET | `/_matrix/client/v3/rooms/{roomId}/messages` | Get message history |
| GET | `/_matrix/client/v3/rooms/{roomId}/joined_members` | Get room members |
| GET | `/_matrix/client/v3/joined_rooms` | Get joined rooms list |

#### Messaging

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/{eventType}/{txnId}` | Send message |
| PUT | `/_matrix/client/v3/rooms/{roomId}/redact/{eventId}` | Redact message |

#### Room Discovery

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_matrix/client/v3/directory/room/{alias}` | Resolve room alias |

#### User Directory

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_matrix/client/v3/user_directory/search` | Search users |

#### Sync

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_matrix/client/v3/sync` | Long-polling sync |

#### Spaces

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_matrix/client/v1/rooms/{roomId}/spaces` | Get space children |
| PUT | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | Add child to space |
| DELETE | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | Remove child from space |

### Unimplemented APIs

The following Matrix Client-Server API endpoints are not yet implemented:

#### Content Repository (Media)
- `GET /_matrix/media/v3/download/{serverName}/{mediaId}` - Download media
- `GET /_matrix/media/v3/thumbnail/{serverName}/{mediaId}` - Get thumbnail
- `POST /_matrix/media/v3/upload` - Upload media

#### User Data
- `GET /_matrix/client/v3/user/{userId}/displayname` - Get display name
- `PUT /_matrix/client/v3/user/{userId}/displayname` - Set display name
- `GET /_matrix/client/v3/user/{userId}/avatar_url` - Get avatar URL
- `PUT /_matrix/client/v3/user/{userId}/avatar_url` - Set avatar URL

#### Account Management
- `POST /_matrix/client/v3/account/password` - Change password
- `POST /_matrix/client/v3/account/deactivate` - Deactivate account
- `GET /_matrix/client/v3/account/whoami` - Already implemented

#### Device Management
- `GET /_matrix/client/v3/devices` - List devices
- `GET /_matrix/client/v3/devices/{deviceId}` - Get device
- `PUT /_matrix/client/v3/devices/{deviceId}` - Update device
- `DELETE /_matrix/client/v3/devices/{deviceId}` - Delete device

#### End-to-End Encryption
- `GET /_matrix/client/v3/keys/query` - Query device keys
- `POST /_matrix/client/v3/keys/upload` - Upload device keys
- `POST /_matrix/client/v3/room/keys/query` - Query room keys
- `POST /_matrix/client/v3/room/keys/upload` - Upload room keys

#### Room Tags
- `GET /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags` - Get room tags
- `PUT /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` - Add room tag
- `DELETE /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` - Remove room tag

#### Push Notifications
- `GET /_matrix/client/v3/pushrules` - Get push rules
- `GET /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - Get push rule
- `PUT /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - Set push rule
- `DELETE /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - Delete push rule

#### Read Markers
- `POST /_matrix/client/v3/rooms/{roomId}/read_markers` - Set read markers

#### Filtering
- `GET /_matrix/client/v3/user/{userId}/filter` - Get filter
- `POST /_matrix/client/v3/user/{userId}/filter` - Create filter

#### Thirdparty APIs
- `GET /_matrix/client/v3/thirdparty/protocols` - Get thirdparty protocols
- `GET /_matrix/client/v3/thirdparty/protocol/{protocol}` - Get thirdparty protocol
- `GET /_matrix/client/v3/thirdparty/user/{protocol}` - Search thirdparty users
- `GET /_matrix/client/v3/thirdparty/location/{protocol}` - Search thirdparty locations

## Project Structure

### Core Services

| Service | Description |
|---------|-------------|
| `AuthManager` | Authentication and session management |
| `SyncManager` | Long-polling sync engine |
| `RoomManager` | Room CRUD operations |
| `MessageManager` | Message sending and receiving |
| `EventProcessor` | Matrix event handling |

### Data Models

| Class | Description |
|-------|-------------|
| `Session` | User session with access token |
| `Room` | Room with display name handling |
| `Message` | Message with body extraction |
| `User` | User profile |

### Storage

- **SecureStorage** - Encrypted session token storage
- **LocalDatabase** - SQLite for rooms and messages cache

## Configuration

### main_pages.json

Route configuration for the app:

```json
{
  "src": [
    "pages/LoginPage",
    "pages/RegisterPage",
    "pages/MainPage",
    "pages/RoomDetailPage",
    "pages/SearchPage",
    "pages/JoinRoomPage",
    "pages/SpacePage",
    "pages/SpaceDetailPage"
  ]
}
```

### module.json5

App module settings including permissions:

```json
{
  "requestPermissions": [
    { "name": "ohos.permission.INTERNET" }
  ]
}
```

## Development

### Code Style

This project follows **ArkTS strict mode** rules:

- No `any` or `unknown` types
- No destructuring declarations
- Explicit type annotations required
- Error objects must be thrown with `throw new Error()`

See [AGENTS.md](AGENTS.md) for detailed guidelines.

### Adding a New Feature

1. **API**: Add method to `MatrixHttpClient.ets`
2. **Types**: Add response types to `MatrixTypes.ets`
3. **Service**: Create wrapper in appropriate Manager
4. **UI**: Create page in `pages/` and add route

## License

MIT License

## Contributing

Contributions are welcome! Please read the code style guidelines in `AGENTS.md` before submitting PRs.
