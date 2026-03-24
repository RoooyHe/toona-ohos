# Toona - Matrix Client for HarmonyOS

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS-000000?style=flat-square&logo=huawei" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Matrix-v3-green?style=flat-square&logo=matrix" alt="Matrix">
</p>

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

### Supported Endpoints

- `/_matrix/client/v3/login` - Authentication
- `/_matrix/client/v3/register` - Registration
- `/_matrix/client/v3/sync` - Initial sync and long-polling
- `/_matrix/client/v3/rooms/{roomId}/messages` - Message history
- `/_matrix/client/v3/createRoom` - Room creation
- `/_matrix/client/v3/rooms/{roomId}/join` - Join room
- `/_matrix/client/v3/account/whoami` - Token validation

### Space API

- `/_matrix/client/v1/rooms/{roomId}/spaces` - Get space children
- `m.space.child` state events - Space hierarchy

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
    "pages/SpacePage"
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
