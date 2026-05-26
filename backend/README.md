# 磊磊音乐后端服务

## 功能
提供歌曲列表信息（使用公共读方式直接访问阿里云OSS）

## 安装与启动

```bash
# 进入后端目录
cd backend

# 安装依赖
npm install

# 启动服务
npm start
```

服务将在 http://localhost:3000 启动。

## API 接口

### 获取歌曲列表URL
- **URL**: GET /api/songs
- **响应**:
```json
{
  "success": true,
  "data": {
    "songListUrl": "https://shamwl-project.oss-cn-beijing.aliyuncs.com/song-list.json"
  }
}
```

## OSS 配置要求

确保您的阿里云 OSS Bucket 配置为公共读权限：

1. 登录阿里云 OSS 控制台
2. 找到您的 Bucket（shamwl-project）
3. 在"权限管理" -> "Bucket授权策略"中添加公共读策略

### 公共读策略配置
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

## 歌曲列表 JSON 格式

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

## 说明

- 本服务不再使用 STS 临时凭证
- 所有 OSS 文件（歌曲列表JSON、MP3文件、封面图片）均通过公共读方式访问
- 无需配置 AccessKey，确保 Bucket 配置正确的公共读权限即可