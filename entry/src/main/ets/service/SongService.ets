import http from '@ohos.net.http';
import { Song, AppConfig, SongListResponse, SongDataItem } from '../model/SongModel';

/**
 * 歌曲数据服务
 * 负责从OSS获取歌曲列表和歌曲信息
 */
export class SongService {
  private static instance: SongService;
  private songList: Song[] = [];
  private isLoading: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): SongService {
    if (!SongService.instance) {
      SongService.instance = new SongService();
    }
    return SongService.instance;
  }

  /**
   * 获取歌曲列表
   */
  public async getSongList(): Promise<Song[]> {
    if (this.songList.length > 0) {
      return this.songList;
    }

    if (this.isLoading) {
      return new Promise((resolve: (value: Song[]) => void) => {
        const checkInterval = setInterval(() => {
          if (!this.isLoading) {
            clearInterval(checkInterval);
            resolve(this.songList);
          }
        }, 100);
      });
    }

    return this.fetchSongList();
  }

  /**
   * 从OSS获取歌曲列表
   */
  private async fetchSongList(): Promise<Song[]> {
    this.isLoading = true;

    try {
      console.info('开始获取歌曲列表...');

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(AppConfig.SONG_LIST_URL, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        }
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as SongListResponse;
        this.songList = this.parseSongList(result);
        console.info('歌曲列表获取成功，共', this.songList.length, '首');
        httpRequest.destroy();
        this.isLoading = false;
        return this.songList;
      } else {
        console.error('获取歌曲列表失败，HTTP状态码:', response.responseCode);
        httpRequest.destroy();
        this.isLoading = false;
        return this.getMockSongList();
      }
    } catch (error) {
      console.error('获取歌曲列表失败:', error);
      this.isLoading = false;
      return this.getMockSongList();
    }
  }

  /**
   * 解析歌曲列表数据
   */
  private parseSongList(data: SongListResponse): Song[] {
    if (!data || !data.songs || !Array.isArray(data.songs)) {
      console.warn('歌曲列表数据格式不正确，使用模拟数据');
      return this.getMockSongList();
    }

    return data.songs.map((item: SongDataItem, index: number) => {
      const song: Song = {
        id: item.id || `song_${index}`,
        name: item.name || '未知歌曲',
        author: item.author || '未知歌手',
        album: item.album || '未知专辑',
        duration: item.duration || 180,
        ossPath: item.ossPath || `${AppConfig.OSS.songFolder}/${item.id || `song_${index}`}.mp3`,
        coverUrl: item.coverUrl || '',
        lyrics: item.lyrics || ''
      };
      return song;
    });
  }

  /**
   * 获取模拟歌曲列表（用于开发和测试）
   */
  private getMockSongList(): Song[] {
    const song1: Song = {
      id: 'song_001',
      name: '晴天',
      author: '周杰伦',
      album: '叶惠美',
      duration: 267,
      ossPath: 'song/song_001.mp3',
      coverUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/covers/song_001.jpg',
      lyrics: '[00:00.00]晴天 - 周杰伦\n[00:05.00]\n[00:10.00]故事的小黄花\n[00:15.00]从出生那年就飘着\n[00:20.00]童年的荡秋千\n[00:25.00]随记忆一直晃到现在'
    };
    const song2: Song = {
      id: 'song_002',
      name: '稻香',
      author: '周杰伦',
      album: '魔杰座',
      duration: 217,
      ossPath: 'song/song_002.mp3',
      coverUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/covers/song_002.jpg',
      lyrics: '[00:00.00]稻香 - 周杰伦\n[00:05.00]\n[00:10.00]还记得你说家是唯一的城堡\n[00:15.00]随着稻香河流继续奔跑'
    };
    const song3: Song = {
      id: 'song_003',
      name: '夜曲',
      author: '周杰伦',
      album: '十一月的萧邦',
      duration: 252,
      ossPath: 'song/song_003.mp3',
      coverUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/covers/song_003.jpg',
      lyrics: '[00:00.00]夜曲 - 周杰伦\n[00:05.00]\n[00:10.00]一群嗜血的蚂蚁'
    };
    const song4: Song = {
      id: 'song_004',
      name: '青花瓷',
      author: '周杰伦',
      album: '我很忙',
      duration: 231,
      ossPath: 'song/song_004.mp3',
      coverUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/covers/song_004.jpg',
      lyrics: '[00:00.00]青花瓷 - 周杰伦\n[00:05.00]\n[00:10.00]素胚勾勒出青花'
    };
    const song5: Song = {
      id: 'song_005',
      name: '告白气球',
      author: '周杰伦',
      album: '周杰伦的床边故事',
      duration: 222,
      ossPath: 'song/song_005.mp3',
      coverUrl: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/covers/song_005.jpg',
      lyrics: '[00:00.00]告白气球 - 周杰伦\n[00:05.00]\n[00:10.00]塞纳河畔 左岸的咖啡'
    };
    return [song1, song2, song3, song4, song5];
  }

  /**
   * 根据ID获取歌曲
   */
  public getSongById(songId: string): Song | undefined {
    return this.songList.find((song: Song) => song.id === songId);
  }

  /**
   * 搜索歌曲
   */
  public searchSongs(keyword: string): Song[] {
    if (!keyword.trim()) {
      return this.songList;
    }

    const lowerKeyword = keyword.toLowerCase();
    return this.songList.filter((song: Song) =>
      song.name.toLowerCase().includes(lowerKeyword) ||
      song.author.toLowerCase().includes(lowerKeyword) ||
      song.album.toLowerCase().includes(lowerKeyword)
    );
  }

  /**
   * 获取随机推荐歌曲
   */
  public getRandomRecommendations(count: number = 20): Song[] {
    if (this.songList.length <= count) {
      return this.songList;
    }

    const shuffled = [...this.songList].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, count);
  }

  /**
   * 刷新歌曲列表
   */
  public async refreshSongList(): Promise<Song[]> {
    this.songList = [];
    this.isLoading = false;
    return this.fetchSongList();
  }
}
