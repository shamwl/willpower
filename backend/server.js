/**
 * 磊磊音乐后端服务
 * 提供歌曲列表信息（使用公共读方式）
 */

const express = require('express');
const router = express.Router();

/**
 * 获取歌曲列表URL
 * GET /api/songs
 * 使用公共读方式直接访问OSS
 */
router.get('/songs', async (req, res) => {
  try {
    // 返回歌曲列表JSON文件的公共读URL
    res.json({
      success: true,
      data: {
        songListUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/song-list.json'
      }
    });
  } catch (error) {
    console.error('获取歌曲列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取歌曲列表失败',
      error: error.message
    });
  }
});

module.exports = router;