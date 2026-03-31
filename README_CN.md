# Toona - HarmonyOS Matrix 客户端

<p align="center">
  <img src="../AppScope/resources/base/media/1024.jpg" alt="Toona Logo" width="128" height="128" style="border-radius: 24px;">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-HarmonyOS-000000?style=flat-square&logo=huawei" alt="Platform">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=flat-square" alt="Language">
  <img src="https://img.shields.io/badge/Matrix-v3-green?style=flat-square&logo=matrix" alt="Matrix">
</p>

[English](./README.md) | 中文版

Toona 是一款基于 HarmonyOS（鸿蒙OS）开发的 Matrix 客户端应用，参考 ElementX/Element Android 客户端架构设计。

## 功能特性

- **身份认证** - Matrix homeserver 登录/注册
- **会话持久化** - 加密令牌存储，自动恢复会话
- **实时同步** - 长轮询同步引擎，实时接收更新
- **房间管理** - 创建、加入、离开房间
- **消息收发** - 发送和接收文本消息
- **私聊会话** - 与其他用户开启 DM 对话
- **空间支持** - 层级式房间组织结构
- **深色模式** - 主题切换支持

## 截图

<!-- 截图待添加 -->

## 架构设计

```
toona/src/main/ets/
├── network/           # Matrix API HTTP 客户端
├── models/            # 数据模型和 Matrix 类型定义
├── database/          # SQLite 本地存储
├── storage/           # SecureStorage 加密会话存储
├── services/          # 业务逻辑 (Auth、Sync、Room、Message)
├── pages/             # UI 页面
├── utils/             # 工具类 (ThemeManager)
└── toonaability/      # 应用入口
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
    "pages/RoomListPage",
    "pages/SearchPage",
    "pages/JoinRoomPage",
    "pages/JoinSpacePage",
    "pages/SpacePage",
    "pages/SpaceDetailPage",
    "pages/SettingsPage"
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
