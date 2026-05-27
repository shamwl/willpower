# 磊磊音乐 - HarmonyOS 音频播放器

基于 HarmonyOS NEXT 的音频播放器应用，支持在线流媒体播放。

## 项目结构

```
shamwl/
└── entry/src/main/
    ├── ets/
    │   ├── model/                      # 数据模型
    │   │   └── SongModel.ets           # 歌曲、播放状态等数据模型
    │   │
    │   ├── service/                    # 业务服务
    │   │   ├── MusicPlayerService.ets  # 音频播放服务（AVPlayer）
    │   │   └── PreferencesService.ets  # 本地存储服务（收藏/下载记录）
    │   │
    │   └── pages/                      # 页面组件
    │       ├── StartLoadingPage.ets    # 启动加载页
    │       ├── MainTabs.ets           # 主导航页面（TabBar）
    │       ├── discover/               # 发现页面
    │       │   └── DiscoverPage.ets   # 推荐歌曲 + 搜索功能
    │       ├── mydownload/            # 我的下载页面
    │       │   └── MyDownloadPage.ets # 收藏列表
    │       ├── player/                 # 播放器页面
    │       │   └── PlayerPage.ets     # 音频播放控制
    │       └── my/                     # 我的页面
    │           └── MyPage.ets         # 用户信息展示
    │
    └── resources/
        └── rawfile/
            └── encoded_songs.json      # 歌曲数据（已编码）
```

## 主要功能

### 1. 发现页面
- **推荐歌曲**：从 `encoded_songs.json` 加载推荐歌曲列表
- **歌曲搜索**：支持按歌曲名、歌手搜索

### 2. 我的下载页面
- **我的收藏**：收藏喜欢的歌曲（使用 Preferences 存储）
- **收藏管理**：查看和取消收藏

### 3. 播放器页面
- **在线流媒体播放**：直接播放网络音频文件，无需下载
- **播放控制**：播放/暂停、上一首/下一首、进度跳转
- **歌曲信息**：显示歌曲名、歌手、专辑信息
- **歌词显示**：支持歌词展示

### 4. 我的页面
- **用户信息**：显示用户基本信息

## 技术架构

### 音频播放
- **播放器**：HarmonyOS AVPlayer API
- **播放方式**：在线流媒体播放（HTTP/HTTPS URL）
- **播放流程**：
  1. 从 `rawfile/encoded_songs.json` 获取歌曲 URL
  2. 使用 AVPlayer 直接播放在线音频流
  3. 支持进度跳转（Seek）

### 数据存储
- **Preferences**：使用 HarmonyOS Preferences 存储用户收藏信息
- **歌曲数据**：从 `rawfile/encoded_songs.json` 读取（应用内置）

### 在线播放原理
```
┌─────────────────────────────────────────────────────────┐
│                    播放流程                              │
├─────────────────────────────────────────────────────────┤
│  encoded_songs.json → 获取歌曲URL → AVPlayer设置播放源  │
│                     → prepare() → play() → 播放输出     │
└─────────────────────────────────────────────────────────┘
```

## 歌曲数据格式

`rawfile/encoded_songs.json` 文件格式：

```json
{
  "songs": [
    {
      "id": "song_001",
      "name": "歌曲名称",
      "author": "歌手名",
      "album": "专辑名",
      "duration": 180,
      "ossPath": "https://your-bucket.oss-cn-beijing.aliyuncs.com/song/song_001.mp3",
      "coverUrl": "封面图片URL",
      "lyrics": "[00:00.00]歌词内容"
    }
  ]
}
```

## 运行项目

### 1. 配置要求
- **DevEco Studio**：最新版本
- **HarmonyOS SDK**：API 12 或更高

### 2. 运行步骤
1. 在 DevEco Studio 中打开项目
2. 配置 HarmonyOS 模拟器或连接真机
3. 点击运行按钮

### 3. 网络权限
确保 `module.json5` 中配置了网络权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.INTERNET"
    }
  ]
}
```

## 开发注意事项

### 1. URL 格式要求
- 歌曲 URL 必须以 `http://` 或 `https://` 开头
- 支持 MP3、AAC、FLAC 等常见音频格式
- 服务器需支持 CORS 或允许跨域访问

### 2. 播放器状态管理
- 每次播放前需释放旧播放器资源
- 遵循 AVPlayer 状态机流程：`initialized → prepared → playing`

### 3. 模拟器测试
- 支持在 HarmonyOS 模拟器上测试
- 确保模拟器网络连接正常

## 核心服务说明

### MusicPlayerService（音乐播放服务）
- **单例模式**：全局唯一播放器实例
- **主要方法**：
  - `play(song)`：播放指定歌曲
  - `pause()`：暂停播放
  - `resume()`：恢复播放
  - `playPrev()` / `playNext()`：上一首/下一首
  - `seek(position)`：跳转到指定位置

### PreferencesService（本地存储服务）
- **单例模式**：管理用户偏好设置
- **主要方法**：
  - `addFavorite(songId)`：添加收藏
  - `removeFavorite(songId)`：取消收藏
  - `isFavorite(songId)`：检查是否收藏

## 更新历史

### v1.1（最新）
- ✅ 移除 SongService，直接从 rawfile 读取歌曲数据
- ✅ 改为在线流媒体播放，无需下载到沙箱
- ✅ 修复启动页面路由问题
- ✅ 优化播放器状态管理

### v1.0（初始版本）
- ✅ 基础播放功能
- ✅ 收藏功能
- ✅ 搜索功能
- ✅ 页面导航

## License

MIT License
