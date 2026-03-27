# Toona - HarmonyOS Matrix 客户端

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS-000000?style=flat-square&logo=huawei" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Matrix-v3-green?style=flat-square&logo=matrix" alt="Matrix">
</p>

Toona 是一款基于 HarmonyOS（鸿蒙OS）开发的 Matrix 客户端应用，参考 ElementX/Element Android 客户端架构设计。

## 功能特性

- **身份认证** - Matrix homeserver 登录/注册
- **会话持久化** - 加密令牌存储，自动恢复会话
- **实时同步** - 长轮询同步引擎，实时接收更新
- **房间管理** - 创建、加入、离开房间
- **消息收发** - 发送和接收文本消息
- **私聊会话** - 与其他用户开启 DM 对话
- **空间支持** - 层级式房间组织结构
- **搜索功能** - 搜索用户和房间

## 截图

<!-- 截图待添加 -->

## 架构设计

```
toona/src/main/ets/
├── network/           # Matrix API HTTP 客户端
├── models/            # 数据模型和 Matrix 类型定义
├── database/          # SQLite 本地存储
├── storage/          # SecureStorage 加密会话存储
├── services/         # 业务逻辑 (Auth、Sync、Room、Message)
├── pages/            # UI 页面
└── toonaability/     # 应用入口
```

### 技术栈

- **框架**: HarmonyOS + ArkTS（严格模式）
- **架构**: MVVM + 仓库模式
- **存储**: SQLite（本地）+ 加密偏好设置（会话）
- **网络**: `@kit.NetworkKit` HTTP 客户端

## 快速开始

### 环境要求

- DevEco Studio（最新版本）
- HarmonyOS SDK
- Node.js（用于 hvigor）

### 编译

1. 在 DevEco Studio 中打开项目
2. 选择 `toona` 模块
3. 点击 **Build** > **Build Module**
4. 或使用命令行：
   ```bash
   hvigor build -m toona
   ```

### 编译命令

| 命令 | 说明 |
|------|------|
| `hvigor build` | 完整编译 |
| `hvigor clean` | 清理编译产物 |
| `hvigor build -m toona` | 编译指定模块 |
| `hvigor build --mode debug` | 调试模式编译 |

## Matrix API

本客户端实现了 [Matrix 客户端-服务端 API v3](https://matrix.org/docs/api/client-server/)。

### 已实现接口

#### 认证

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/_matrix/client/v3/login` | 用户名密码登录 |
| POST | `/_matrix/client/v3/register` | 注册新账户 |
| POST | `/_matrix/client/v3/logout` | 登出当前会话 |
| GET | `/_matrix/client/v3/account/whoami` | 验证令牌获取用户ID |
| GET | `/_matrix/client/versions` | 检查服务器版本 |

#### 房间管理

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/_matrix/client/v3/createRoom` | 创建房间或空间 |
| POST | `/_matrix/client/v3/rooms/{roomId}/join` | 加入房间 |
| POST | `/_matrix/client/v3/rooms/{roomId}/leave` | 离开房间 |
| POST | `/_matrix/client/v3/rooms/{roomId}/invite` | 邀请用户 |
| POST | `/_matrix/client/v3/rooms/{roomId}/kick` | 踢出用户 |
| POST | `/_matrix/client/v3/rooms/{roomId}/ban` | 封禁用户 |
| POST | `/_matrix/client/v3/rooms/{roomId}/unban` | 解除封禁 |
| POST | `/_matrix/client/v3/rooms/{roomId}/forget` | 遗忘房间 |

#### 房间状态

| 方法 | 端点 | 说明 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | 设置房间名称 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | 设置房间主题 |
| GET | `/_matrix/client/v3/rooms/{roomId}/messages` | 获取消息历史 |
| GET | `/_matrix/client/v3/rooms/{roomId}/joined_members` | 获取房间成员 |
| GET | `/_matrix/client/v3/joined_rooms` | 获取已加入房间列表 |

#### 消息

| 方法 | 端点 | 说明 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/{eventType}/{txnId}` | 发送消息 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/redact/{eventId}` | 删除消息 |

#### 房间发现

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/_matrix/client/v3/directory/room/{alias}` | 解析房间别名 |

#### 用户目录

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/_matrix/client/v3/user_directory/search` | 搜索用户 |

#### 同步

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/_matrix/client/v3/sync` | 长轮询同步 |

#### 空间

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/_matrix/client/v1/rooms/{roomId}/spaces` | 获取空间子项 |
| PUT | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | 添加子房间到空间 |
| DELETE | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | 从空间移除子房间 |

### 未实现接口

以下 Matrix 客户端-服务端 API 端点尚未实现：

#### 内容仓库（媒体）
- `GET /_matrix/media/v3/download/{serverName}/{mediaId}` - 下载媒体
- `GET /_matrix/media/v3/thumbnail/{serverName}/{mediaId}` - 获取缩略图
- `POST /_matrix/media/v3/upload` - 上传媒体

#### 用户数据
- `GET /_matrix/client/v3/user/{userId}/displayname` - 获取显示名称
- `PUT /_matrix/client/v3/user/{userId}/displayname` - 设置显示名称
- `GET /_matrix/client/v3/user/{userId}/avatar_url` - 获取头像 URL
- `PUT /_matrix/client/v3/user/{userId}/avatar_url` - 设置头像 URL

#### 账户管理
- `POST /_matrix/client/v3/account/password` - 修改密码
- `POST /_matrix/client/v3/account/deactivate` - 注销账户

#### 设备管理
- `GET /_matrix/client/v3/devices` - 列出设备
- `GET /_matrix/client/v3/devices/{deviceId}` - 获取设备信息
- `PUT /_matrix/client/v3/devices/{deviceId}` - 更新设备
- `DELETE /_matrix/client/v3/devices/{deviceId}` - 删除设备

#### 端到端加密
- `POST /_matrix/client/v3/keys/query` - 查询设备密钥
- `POST /_matrix/client/v3/keys/upload` - 上传设备密钥
- `POST /_matrix/client/v3/room/keys/query` - 查询房间密钥
- `POST /_matrix/client/v3/room/keys/upload` - 上传房间密钥

#### 房间标签
- `GET /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags` - 获取房间标签
- `PUT /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` - 添加房间标签
- `DELETE /_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` - 删除房间标签

#### 推送通知
- `GET /_matrix/client/v3/pushrules` - 获取推送规则
- `GET /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - 获取推送规则
- `PUT /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - 设置推送规则
- `DELETE /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` - 删除推送规则

#### 已读标记
- `POST /_matrix/client/v3/rooms/{roomId}/read_markers` - 设置已读标记

#### 过滤器
- `GET /_matrix/client/v3/user/{userId}/filter` - 获取过滤器
- `POST /_matrix/client/v3/user/{userId}/filter` - 创建过滤器

#### 第三方 API
- `GET /_matrix/client/v3/thirdparty/protocols` - 获取第三方协议
- `GET /_matrix/client/v3/thirdparty/protocol/{protocol}` - 获取第三方协议详情
- `GET /_matrix/client/v3/thirdparty/user/{protocol}` - 搜索第三方用户
- `GET /_matrix/client/v3/thirdparty/location/{protocol}` - 搜索第三方位置

## 项目结构

### 核心服务

| 服务 | 说明 |
|------|------|
| `AuthManager` | 身份认证和会话管理 |
| `SyncManager` | 长轮询同步引擎 |
| `RoomManager` | 房间 CRUD 操作 |
| `MessageManager` | 消息发送和接收 |
| `EventProcessor` | Matrix 事件处理 |

### 数据模型

| 类 | 说明 |
|---|------|
| `Session` | 用户会话，包含访问令牌 |
| `Room` | 房间，含显示名称处理 |
| `Message` | 消息，含消息体提取 |
| `User` | 用户资料 |

### 存储

- **SecureStorage** - 加密会话令牌存储
- **LocalDatabase** - SQLite 房间和消息缓存

## 配置

### main_pages.json

应用路由配置：

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

应用模块配置，包含权限：

```json
{
  "requestPermissions": [
    { "name": "ohos.permission.INTERNET" }
  ]
}
```

## 开发

### 代码规范

本项目遵循 **ArkTS 严格模式** 规则：

- 禁止使用 `any` 或 `unknown` 类型
- 禁止解构声明
- 必须显式声明类型注解
- 必须使用 `throw new Error()` 抛出错误对象

详细规范请参阅 [AGENTS.md](AGENTS.md)。

### 新增功能

1. **API**: 在 `MatrixHttpClient.ets` 添加方法
2. **类型**: 在 `MatrixTypes.ets` 添加响应类型
3. **服务**: 在对应的 Manager 中创建封装
4. **UI**: 在 `pages/` 创建页面并添加路由

## 许可证

MIT 许可证

## 贡献

欢迎提交贡献！提交 PR 前请阅读 `AGENTS.md` 中的代码规范指南。
