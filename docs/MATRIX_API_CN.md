# Matrix 客户端-服务端 API v3 文档

> Toona Matrix 客户端 for HarmonyOS - API 实现状态

## 概述

本文档列出了 [Matrix 规范](https://matrix.org/docs/api/client-server/) 中定义的所有 Matrix 客户端-服务端 API 接口。每个接口都标注为 **已实现** 或 **未实现**。

---

## API 版本

| 版本 | 状态 | 说明 |
|------|------|------|
| `/_matrix/client/v3/` | 当前版本 | 主要 API 版本 |
| `/_matrix/client/r0/` | 已支持 | Rack 兼容版本 |
| `/_matrix/client/v1/` | 部分使用 | 旧版，用于部分 Space API |
| `/_matrix/client/versions` | ✅ 已实现 | 服务器版本发现 |

---

## 认证 (Authentication)

### 登录
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/login` | ✅ 已实现 |
| POST | `/_matrix/client/r0/login` | ✅ 已实现 |

### 注册
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/register` | ✅ 已实现 |
| POST | `/_matrix/client/r0/register` | ✅ 已实现 |

### 登出
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/logout` | ✅ 已实现 |
| POST | `/_matrix/client/v3/logout/all` | ❌ 未实现 |

### 身份验证
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/account/whoami` | ✅ 已实现 |

### 令牌管理
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/account/deactivate` | ❌ 未实现 |
| POST | `/_matrix/client/v3/account/password` | ❌ 未实现 |

---

## 房间管理 (Room Management)

### 创建房间
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/createRoom` | ✅ 已实现 |

### 加入房间
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/rooms/{roomId}/join` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/join` | ✅ 已实现 |
| POST | `/_matrix/client/v3/join/{roomIdOrAlias}` | ✅ 已实现 |
| POST | `/_matrix/client/v3/rooms/{roomId}/leave` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/leave` | ✅ 已实现 |

### 房间成员
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/rooms/{roomId}/invite` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/invite` | ✅ 已实现 |
| POST | `/_matrix/client/v3/rooms/{roomId}/kick` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/kick` | ✅ 已实现 |
| POST | `/_matrix/client/v3/rooms/{roomId}/ban` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/ban` | ✅ 已实现 |
| POST | `/_matrix/client/v3/rooms/{roomId}/unban` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/unban` | ✅ 已实现 |
| POST | `/_matrix/client/v3/rooms/{roomId}/forget` | ✅ 已实现 |
| POST | `/_matrix/client/r0/rooms/{roomId}/forget` | ✅ 已实现 |

### 获取房间成员
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/joined_members` | ✅ 已实现 |
| GET | `/_matrix/client/r0/rooms/{roomId}/joined_members` | ✅ 已实现 |
| GET | `/_matrix/client/v3/rooms/{roomId}/members` | ❌ 未实现 |
| GET | `/_matrix/client/v3/rooms/{roomId}/state` | ❌ 未实现 |

### 已加入房间列表
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/joined_rooms` | ✅ 已实现 |
| GET | `/_matrix/client/r0/joined_rooms` | ✅ 已实现 |

---

## 房间状态 (Room State)

### 获取/设置房间状态
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/{eventType}` | ✅ 已实现 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/{eventType}/{stateKey}` | ✅ 已实现 |

### 房间名称
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | ✅ 通过 Sync |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.name` | ✅ 已实现 |

### 房间主题
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | ✅ 通过 Sync |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.topic` | ✅ 已实现 |

### 房间头像
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.avatar` | ❌ 未实现 |

### 规范别名
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/canonical_alias` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.canonical_alias` | ❌ 未实现 |

### 房间别名列表
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/aliases` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/rooms/{roomId}/state/m.room.aliases` | ❌ 未实现 |

---

## 房间发现 (Room Discovery)

### 解析别名
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/directory/room/{roomAlias}` | ✅ 已实现 |
| PUT | `/_matrix/client/v3/directory/room/{roomAlias}` | ❌ 未实现 |
| DELETE | `/_matrix/client/v3/directory/room/{roomAlias}` | ❌ 未实现 |

### 房间目录
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/publicRooms` | ❌ 未实现 |
| POST | `/_matrix/client/v3/publicRooms` | ❌ 未实现 |
| GET | `/_matrix/client/r0/publicRooms` | ❌ 未实现 |
| POST | `/_matrix/client/r0/publicRooms` | ❌ 未实现 |

---

## 消息 (Messaging)

### 发送消息
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/{eventType}/{txnId}` | ✅ 已实现 |
| PUT | `/_matrix/client/r0/rooms/{roomId}/send/{eventType}/{txnId}` | ✅ 已实现 |

### 消息类型
| 事件类型 | 状态 |
|----------|------|
| `m.room.message` | ✅ 已实现 |
| `m.room.emote` | ✅ 已实现 |
| `m.room.notice` | ✅ 已实现 |
| `m.sticker` | ❌ 未实现 |

### 获取消息
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/rooms/{roomId}/messages` | ✅ 已实现 |
| GET | `/_matrix/client/r0/rooms/{roomId}/messages` | ✅ 已实现 |

### 删除消息
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/redact/{eventId}/{txnId}` | ✅ 已实现 |
| PUT | `/_matrix/client/r0/rooms/{roomId}/redact/{eventId}/{txnId}` | ✅ 已实现 |

### 消息反应
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}/m.annotation` | ❌ 未实现 |
| GET | `/_matrix/client/v3/rooms/{roomId}/relations/{eventId}` | ❌ 未实现 |

### 编辑消息
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}` | ✅ 已实现 |

### 回复消息
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}` | ✅ 已实现 |

### 已读标记
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/rooms/{roomId}/read_markers` | ❌ 未实现 |

### 正在输入
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{roomId}/typing/{userId}` | ❌ 未实现 |
| GET | `/_matrix/client/v3/rooms/{roomId}/typing/{userId}` | ❌ 未实现 |

### 回执
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/rooms/{roomId}/receipt/{receiptType}/{eventId}` | ❌ 未实现 |
| GET | `/_matrix/client/v3/rooms/{roomId}/receipt/{receiptType}/{eventId}` | ❌ 未实现 |

---

## 同步 (Sync)

### 同步
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/sync` | ✅ 已实现 |
| GET | `/_matrix/client/r0/sync` | ✅ 已实现 |

### 初始同步 (已废弃)
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/initialSync` | ❌ 未实现 |
| GET | `/_matrix/client/v3/conInitialSync` | ❌ 未实现 |

---

## 空间 (Spaces)

### 创建空间
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/createRoom` (设置 `type: m.space`) | ✅ 已实现 |

### 获取空间子项
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v1/rooms/{roomId}/spaces` | ✅ 已实现 |

### 添加子空间/房间
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | ✅ 已实现 |

### 移除子空间/房间
| 方法 | 端点 | 状态 |
|------|------|------|
| DELETE | `/_matrix/client/v3/rooms/{parentId}/state/m.space.child/{childId}` | ✅ 已实现 |

### 获取空间层级
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v1/rooms/{roomId}/hierarchy` | ❌ 未实现 |

---

## 用户目录 (User Directory)

### 搜索用户
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/user_directory/search` | ✅ 已实现 |
| GET | `/_matrix/client/v3/user_directory/search` | ✅ 已实现 |

### 用户资料
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/profile/{userId}` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/profile/{userId}` | ❌ 未实现 |

### 显示名称
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/profile/{userId}/displayname` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/profile/{userId}/displayname` | ❌ 未实现 |

### 头像 URL
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/profile/{userId}/avatar_url` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/profile/{userId}/avatar_url` | ❌ 未实现 |

---

## 内容仓库 (媒体) (Content Repository)

### 上传
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/media/v3/upload` | ❌ 未实现 |
| POST | `/_matrix/media/r0/upload` | ❌ 未实现 |

### 下载
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/media/v3/download/{serverName}/{mediaId}` | ❌ 未实现 |
| GET | `/_matrix/media/r0/download/{serverName}/{mediaId}` | ❌ 未实现 |

### 缩略图
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/media/v3/thumbnail/{serverName}/{mediaId}` | ❌ 未实现 |
| GET | `/_matrix/media/r0/thumbnail/{serverName}/{mediaId}` | ❌ 未实现 |

### URL 预览
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/media/v3/preview_url` | ❌ 未实现 |

### 配置
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/media/v3/config` | ❌ 未实现 |

---

## 设备 (Devices)

### 列出设备
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/devices` | ❌ 未实现 |
| GET | `/_matrix/client/r0/devices` | ❌ 未实现 |

### 获取设备
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/devices/{deviceId}` | ❌ 未实现 |

### 更新设备
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/devices/{deviceId}` | ❌ 未实现 |

### 删除设备
| 方法 | 端点 | 状态 |
|------|------|------|
| DELETE | `/_matrix/client/v3/devices/{deviceId}` | ❌ 未实现 |

### 批量删除设备
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/delete_devices` | ❌ 未实现 |

---

## 端到端加密 (End-to-End Encryption)

### 查询密钥
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/keys/query` | ❌ 未实现 |
| POST | `/_matrix/client/r0/keys/query` | ❌ 未实现 |

### 上传密钥
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/keys/upload` | ❌ 未实现 |
| POST | `/_matrix/client/r0/keys/upload` | ❌ 未实现 |

### 索取密钥
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/keys/claim` | ❌ 未实现 |
| POST | `/_matrix/client/r0/keys/claim` | ❌ 未实现 |

### 房间密钥
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/room/keys/query` | ❌ 未实现 |
| POST | `/_matrix/client/v3/room/keys/upload` | ❌ 未实现 |
| GET | `/_matrix/client/v3/room/keys/keys` | ❌ 未实现 |

### 密钥备份
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/room_keys/version` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/room_keys/version` | ❌ 未实现 |
| POST | `/_matrix/client/v3/room_keys/version` | ❌ 未实现 |
| GET | `/_matrix/client/v3/room_keys/keys/{roomId}/{sessionId}` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/room_keys/keys/{roomId}/{sessionId}` | ❌ 未实现 |

### 签名
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/keys/signatures/upload` | ❌ 未实现 |

---

## 房间标签 (Room Tags)

### 获取标签
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags` | ❌ 未实现 |

### 添加标签
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` | ❌ 未实现 |

### 删除标签
| 方法 | 端点 | 状态 |
|------|------|------|
| DELETE | `/_matrix/client/v3/user/{userId}/rooms/{roomId}/tags/{tag}` | ❌ 未实现 |

---

## 推送通知 (Push Notifications)

### 推送规则
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/pushrules` | ❌ 未实现 |
| GET | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ 未实现 |
| PUT | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ 未实现 |
| DELETE | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}` | ❌ 未实现 |

### 推送规则操作
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}/actions` | ❌ 未实现 |

### 通知
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/notifications` | ❌ 未实现 |
| GET | `/_matrix/client/v3/notifications` | ❌ 未实现 |

---

## 过滤器 (Filtering)

### 创建过滤器
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/user/{userId}/filter` | ❌ 未实现 |
| POST | `/_matrix/client/r0/user/{userId}/filter` | ❌ 未实现 |

### 获取过滤器
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/user/{userId}/filter/{filterId}` | ❌ 未实现 |
| GET | `/_matrix/client/r0/user/{userId}/filter/{filterId}` | ❌ 未实现 |

---

## 在线状态 (Presence)

### 获取在线状态
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/presence/{userId}/status` | ❌ 未实现 |

### 设置在线状态
| 方法 | 端点 | 状态 |
|------|------|------|
| PUT | `/_matrix/client/v3/presence/{userId}/status` | ❌ 未实现 |

### 在线状态列表
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/presence/list` | ❌ 未实现 |

---

## 第三方服务 (Thirdparty)

### 协议
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/thirdparty/protocols` | ❌ 未实现 |
| GET | `/_matrix/client/v3/thirdparty/protocol/{protocol}` | ❌ 未实现 |

### 用户搜索
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/thirdparty/user/{protocol}` | ❌ 未实现 |
| POST | `/_matrix/client/v3/thirdparty/user/` | ❌ 未实现 |

### 位置搜索
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/thirdparty/location/{protocol}` | ❌ 未实现 |
| POST | `/_matrix/client/v3/thirdparty/location/` | ❌ 未实现 |

---

## VoIP

### TURN 服务器
| 方法 | 端点 | 状态 |
|------|------|------|
| GET | `/_matrix/client/v3/voip/turnServer` | ❌ 未实现 |

---

## OpenID Connect

### 令牌
| 方法 | 端点 | 状态 |
|------|------|------|
| POST | `/_matrix/client/v3/user/{userId}/openid` | ❌ 未实现 |

---

## 统计汇总

| 分类 | 已实现 | 未实现 | 总计 |
|------|--------|--------|------|
| 认证 | 5 | 2 | 7 |
| 房间管理 | 14 | 2 | 16 |
| 房间状态 | 2 | 11 | 13 |
| 房间发现 | 1 | 5 | 6 |
| 消息 | 4 | 11 | 15 |
| 同步 | 1 | 2 | 3 |
| 空间 | 4 | 0 | 4 |
| 用户目录 | 1 | 4 | 5 |
| 内容仓库 | 0 | 6 | 6 |
| 设备 | 0 | 5 | 5 |
| 端到端加密 | 0 | 10 | 10 |
| 房间标签 | 0 | 3 | 3 |
| 推送通知 | 0 | 6 | 6 |
| 过滤器 | 0 | 2 | 2 |
| 在线状态 | 0 | 3 | 3 |
| 第三方服务 | 0 | 6 | 6 |
| VoIP | 0 | 1 | 1 |
| OpenID | 0 | 1 | 1 |
| **总计** | **32** | **80** | **112** |

**实现进度: 28.6%** (32/112 接口)

---

## 优先级功能 (待实现)

### 高优先级
1. **内容仓库 (媒体)** - 媒体文件上传/下载
2. **用户资料管理** - 显示名称、头像设置
3. **已读回执和正在输入** - 消息状态反馈

### 中优先级
1. **端到端加密支持** - 密钥管理和加密消息
2. **推送通知** - 离线消息推送
3. **房间标签/收藏** - 房间分类管理

### 低优先级
1. **第三方服务 API** - 协议集成
2. **VoIP 支持** - 语音通话
3. **OpenID Connect** - 第三方登录
