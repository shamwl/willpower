# 磊磊音乐 - HarmonyOS 音频播放器

基于 HarmonyOS NEXT 和阿里云 OSS 的音频播放器应用。

## 项目结构

```
leilei-music/
├── backend/                          # Node.js 后端服务
│   ├── server.js                    # 歌曲列表服务
│   ├── package.json                 # 后端依赖配置
│   └── README.md                    # 后端服务说明
│
└── entry/src/main/ets/
    ├── model/                       # 数据模型
    │   └── SongModel.ets           # 歌曲、用户、播放器状态等数据模型
    │
    ├── service/                     # 业务服务
    │   ├── MusicPlayerService.ets  # 音频播放服务（AVPlayer）
    │   ├── SongService.ets         # 歌曲数据服务（OSS公共读）
    │   └── PreferencesService.ets  # 本地存储服务
    │
    └── pages/                      # 页面组件
        ├── StartLoadingPage.ets    # 启动加载页
        ├── MainTabs.ets           # 主导航页面（4个Tab）
        ├── discover/               # 发现页面
        │   └── DiscoverPage.ets   # 推荐 + 搜索
        ├── mydownload/            # 我的下载页面
        │   └── MyDownloadPage.ets # 收藏 + 下载
        ├── player/                 # 播放器页面
        │   └── PlayerPage.ets     # 音频播放控制
        └── my/                     # 我的页面
            └── MyPage.ets         # 用户信息 + 登录注册
```

## 主要功能

### 1. 发现页面
- **推荐歌曲**：随机从曲库抽取20首作为每日推荐
- **歌曲搜索**：支持按歌曲名、歌手、专辑搜索

### 2. 我的下载页面
- **我的收藏**：收藏喜欢的歌曲
- **我的下载**：管理已下载的歌曲

### 3. 播放器页面
- **音频播放**：使用 AVPlayer API 播放音频
- **播放控制**：播放/暂停、上一首/下一首、进度跳转
- **歌曲信息**：显示歌曲名、歌手、专辑封面
- **歌词显示**：支持歌词展示
- **收藏下载**：支持收藏和下载当前歌曲

### 4. 我的页面
- **用户信息**：显示用户基本信息
- **登录注册**：用户登录和注册功能

## 技术架构

### 音频播放
- **播放器**：HarmonyOS AVPlayer API
- **播放流程**：
  1. 从 OSS 通过公共读方式下载歌曲文件到本地临时目录
  2. 使用 AVPlayer 播放本地文件
  3. 支持进度跳转（Seek）

### 数据存储
- **Preferences**：使用 HarmonyOS Preferences 存储用户收藏和下载信息
- **歌曲列表**：从 OSS 获取 JSON 格式的歌曲列表（公共读方式）

### 阿里云 OSS（公共读方式）
- **存储桶**：shamwl-project
- **区域**：cn-beijing
- **Endpoint**：oss-cn-beijing.aliyuncs.com
- **歌曲路径**：song/*.mp3
- **访问方式**：公共读（无需 AccessKey）

### 安全机制
- **公共读权限**：OSS Bucket 配置为公共读，无需硬编码 AccessKey
- **无敏感信息**：前端代码不包含任何阿里云密钥

## 阿里云 OSS 配置

### 1. 配置公共读权限
登录阿里云 OSS 控制台，为您的 Bucket（shamwl-project）配置公共读策略：

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["oss:GetObject"],
      "Resource": ["acs:oss:*:*:shamwl-project/*"]
    }
  ]
}
```

### 2. 上传歌曲文件
将您的 MP3 歌曲文件上传到 OSS 的 `song/` 文件夹，并确保以下文件存在：
- `song-list.json`：歌曲列表 JSON 文件
- `song/*.mp3`：歌曲音频文件

### 3. 歌曲列表 JSON 格式

```json
{
  "songs": [
    {
      "id": "song_001",
      "name": "歌曲名称",
      "author": "歌手名",
      "album": "专辑名",
      "duration": 180,
      "ossPath": "song/song_001.mp3",
      "coverUrl": "封面图片URL",
      "lyrics": "[00:00.00]歌词内容"
    }
  ]
}
```

## 后端服务部署

### 1. 安装依赖
```bash
cd backend
npm install
```

### 2. 启动服务
```bash
npm start
```

服务将在 http://localhost:3000 启动。

### 3. API 接口
- **GET /api/songs**：获取歌曲列表 URL

## 运行项目

### 1. 确保 OSS 配置正确
确保您的 OSS Bucket 配置了公共读权限，并且包含歌曲文件。

### 2. 启动后端服务（可选）
```bash
cd backend
npm install
npm start
```

### 3. 在 DevEco Studio 中运行
打开项目，运行到 HarmonyOS 模拟器或设备。

## 开发注意事项

### 1. 权限配置
确保在 `module.json5` 中配置了必要的权限：
- 网络访问权限
- 文件读写权限

### 2. 模拟器测试
应用支持在 HarmonyOS 模拟器上测试：
- 模拟器版本：5.0.5 (API 17)
- 目标 API 版本：12 或更高

### 3. OSS 公共读配置
确保您的 OSS Bucket 配置了正确的公共读权限，否则将无法访问歌曲文件。

## 未来优化方向

1. **优化音频播放**：支持在线播放而不是下载后播放
2. **歌词同步**：实现歌词滚动和同步显示
3. **用户系统**：完善用户登录注册系统
4. **播放列表**：支持创建和管理播放列表
5. **缓存管理**：优化本地文件缓存管理
6. **离线模式**：支持离线播放已下载的歌曲

## 技术支持

如有问题，请检查：
1. 阿里云 OSS Bucket 是否配置了公共读权限
2. 歌曲列表 JSON 文件是否存在且格式正确
3. 歌曲文件路径是否正确
4. 网络连接是否正常

## License

MIT License