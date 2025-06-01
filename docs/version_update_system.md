# 版本更新检测系统

## 🎯 功能概述

本系统实现了基于GitHub Release的版本更新检测功能，支持自动检查更新、版本比较、更新提醒等功能。

## ✅ 已实现功能

### 1. 核心功能
- **GitHub Release API集成** - 自动获取最新版本信息
- **智能版本比较** - 支持语义化版本号比较
- **自动更新检查** - 应用启动时自动检查（可配置）
- **更新提醒对话框** - 用户友好的更新通知界面
- **版本管理页面** - 完整的版本信息和设置界面

### 2. 配置管理
- **配置文件管理** - 通过 `lib/core/config/app_config.dart` 统一管理
- **开发/生产环境** - 支持不同环境使用不同的GitHub仓库
- **自动检查间隔** - 可配置检查频率（默认24小时）

### 3. 用户界面
- **版本设置页面** - 显示当前版本、GitHub配置、检查更新等
- **更新对话框** - 美观的更新提醒，包含版本信息和更新内容
- **设置集成** - 在应用设置中添加版本管理入口

## 🔧 配置说明

### GitHub仓库配置

编辑 `lib/core/config/app_config.dart` 文件：

```dart
class AppConfig {
  // 生产环境GitHub配置
  static const String githubOwner = 'your-username';    // 替换为你的GitHub用户名
  static const String githubRepo = 'invest_ledger';     // 替换为你的仓库名
  
  // 开发模式配置
  static const bool isDevelopment = false;              // 发布时改为false
  
  // 测试用GitHub配置（开发时使用）
  static const String testGithubOwner = 'flutter';
  static const String testGithubRepo = 'flutter';
}
```

### 配置步骤

1. **设置生产环境仓库**
   ```dart
   static const String githubOwner = 'your-github-username';
   static const String githubRepo = 'your-repository-name';
   ```

2. **发布时关闭开发模式**
   ```dart
   static const bool isDevelopment = false;
   ```

3. **配置检查间隔（可选）**
   ```dart
   static const Duration versionCheckInterval = Duration(hours: 24);
   ```

## 📱 使用说明

### 用户操作

1. **查看版本信息**
   - 进入 设置 → 版本管理
   - 查看当前版本、GitHub配置等信息

2. **手动检查更新**
   - 在版本管理页面点击"立即检查"按钮
   - 系统会检查GitHub Release获取最新版本

3. **自动检查设置**
   - 可以开启/关闭自动检查更新功能
   - 默认每24小时检查一次

4. **更新操作**
   - 发现新版本时会显示更新对话框
   - 可以选择立即更新、稍后提醒或忽略此版本
   - 点击"立即更新"会打开下载页面

### 自动检查机制

- **启动检查** - 应用启动时自动检查（如果启用且超过检查间隔）
- **频率控制** - 避免频繁检查，默认24小时检查一次
- **静默处理** - 检查失败不会影响应用正常使用

## 🏗️ 技术架构

### 文件结构
```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart              # 应用配置
│   └── exceptions/
│       └── app_exceptions.dart          # 异常定义
├── data/
│   ├── models/
│   │   └── version_info.dart            # 版本信息模型
│   ├── services/
│   │   └── version_service.dart         # 版本服务
│   └── repositories/
│       └── version_repository.dart      # 版本仓库
├── presentation/
│   ├── providers/
│   │   └── version_provider.dart        # 状态管理
│   ├── pages/settings/
│   │   └── version_settings_page.dart   # 版本设置页面
│   └── widgets/
│       ├── update_dialog.dart           # 更新对话框
│       └── version_check_wrapper.dart   # 版本检查包装器
└── shared/
    └── widgets/
        └── loading_overlay.dart         # 加载遮罩
```

### 数据流
1. **应用启动** → VersionCheckWrapper → 检查是否需要自动检查
2. **版本服务** → GitHub Release API → 获取最新版本信息
3. **版本比较** → VersionComparator → 判断是否有新版本
4. **状态管理** → Riverpod Provider → 管理检查状态和结果
5. **用户界面** → 显示更新对话框或版本信息

## 🔍 API说明

### GitHub Release API
- **端点**: `https://api.github.com/repos/{owner}/{repo}/releases/latest`
- **方法**: GET
- **头部**: 
  - `Accept: application/vnd.github.v3+json`
  - `User-Agent: InvestLedger-App`

### 响应数据
```json
{
  "tag_name": "v1.2.0",
  "name": "Release 1.2.0",
  "body": "更新内容...",
  "html_url": "https://github.com/owner/repo/releases/tag/v1.2.0",
  "published_at": "2024-01-01T00:00:00Z",
  "prerelease": false,
  "draft": false,
  "assets": [...]
}
```

## 🚀 发布流程

### 创建Release
1. 在GitHub仓库中创建新的Release
2. 设置版本标签（如 v1.2.0）
3. 填写更新说明
4. 上传APK等安装包（可选）
5. 发布Release

### 版本号规范
- 使用语义化版本号：`v{major}.{minor}.{patch}`
- 示例：`v1.0.0`, `v1.2.3`, `v2.0.0-beta.1`
- 支持预发布版本标记

## 🛠️ 开发说明

### 测试配置
开发时可以使用Flutter官方仓库进行测试：
```dart
static const bool isDevelopment = true;
static const String testGithubOwner = 'flutter';
static const String testGithubRepo = 'flutter';
```

### 错误处理
- 网络错误：显示错误信息，不影响应用使用
- API限制：GitHub API有频率限制，系统会自动处理
- 解析错误：版本信息解析失败时会显示相应错误

### 扩展功能
- 支持自定义下载源
- 支持增量更新
- 支持更新进度显示
- 支持更新历史记录

## 📝 注意事项

1. **网络权限** - 确保应用有网络访问权限
2. **GitHub配置** - 发布前务必配置正确的GitHub仓库信息
3. **版本号格式** - 确保Release标签使用正确的版本号格式
4. **用户体验** - 更新检查不应影响应用正常启动和使用
5. **隐私保护** - 版本检查不收集用户个人信息
