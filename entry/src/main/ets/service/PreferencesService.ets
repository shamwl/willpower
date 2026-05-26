import dataPreferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

/**
 * 偏好设置管理服务
 * 用于存储和管理用户的收藏、下载等数据
 */
export class PreferencesService {
  private static instance: PreferencesService;
  private preferences: dataPreferences.Preferences | null = null;
  private context: common.Context | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): PreferencesService {
    if (!PreferencesService.instance) {
      PreferencesService.instance = new PreferencesService();
    }
    return PreferencesService.instance;
  }

  /**
   * 初始化偏好设置
   */
  async init(context: common.Context): Promise<void> {
    try {
      this.context = context;
      this.preferences = await dataPreferences.getPreferences(context, 'leilei_music_prefs');
      console.info('偏好设置初始化成功');
    } catch (error) {
      console.error('偏好设置初始化失败:', error);
    }
  }

  /**
   * 确保初始化
   */
  private async ensureInitialized(): Promise<void> {
    if (!this.preferences) {
      if (!this.context) {
        throw new Error('PreferencesService未初始化，请先调用init方法');
      }
      await this.init(this.context);
    }
  }

  /**
   * 获取收藏歌曲ID列表
   */
  async getFavorites(): Promise<string[]> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const favoritesStr = await this.preferences.get('favorites', '[]') as string;
        return JSON.parse(favoritesStr);
      }
      return [];
    } catch (error) {
      console.error('获取收藏列表失败:', error);
      return [];
    }
  }

  /**
   * 添加收藏歌曲
   */
  async addFavorite(songId: string): Promise<boolean> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const favorites = await this.getFavorites();
        if (!favorites.includes(songId)) {
          favorites.push(songId);
          await this.preferences.put('favorites', JSON.stringify(favorites));
          await this.preferences.flush();
        }
      }
      return true;
    } catch (error) {
      console.error('添加收藏失败:', error);
      return false;
    }
  }

  /**
   * 移除收藏歌曲
   */
  async removeFavorite(songId: string): Promise<boolean> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const favorites = await this.getFavorites();
        const index = favorites.indexOf(songId);
        if (index > -1) {
          favorites.splice(index, 1);
          await this.preferences.put('favorites', JSON.stringify(favorites));
          await this.preferences.flush();
        }
      }
      return true;
    } catch (error) {
      console.error('移除收藏失败:', error);
      return false;
    }
  }

  /**
   * 检查歌曲是否已收藏
   */
  async isFavorite(songId: string): Promise<boolean> {
    try {
      const favorites = await this.getFavorites();
      return favorites.includes(songId);
    } catch (error) {
      console.error('检查收藏状态失败:', error);
      return false;
    }
  }

  /**
   * 获取下载歌曲ID列表
   */
  async getDownloads(): Promise<string[]> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const downloadsStr = await this.preferences.get('downloads', '[]') as string;
        return JSON.parse(downloadsStr);
      }
      return [];
    } catch (error) {
      console.error('获取下载列表失败:', error);
      return [];
    }
  }

  /**
   * 添加下载歌曲
   */
  async addDownload(songId: string): Promise<boolean> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const downloads = await this.getDownloads();
        if (!downloads.includes(songId)) {
          downloads.push(songId);
          await this.preferences.put('downloads', JSON.stringify(downloads));
          await this.preferences.flush();
        }
      }
      return true;
    } catch (error) {
      console.error('添加下载记录失败:', error);
      return false;
    }
  }

  /**
   * 移除下载歌曲
   */
  async removeDownload(songId: string): Promise<boolean> {
    try {
      await this.ensureInitialized();
      if (this.preferences) {
        const downloads = await this.getDownloads();
        const index = downloads.indexOf(songId);
        if (index > -1) {
          downloads.splice(index, 1);
          await this.preferences.put('downloads', JSON.stringify(downloads));
          await this.preferences.flush();
        }
      }
      return true;
    } catch (error) {
      console.error('移除下载记录失败:', error);
      return false;
    }
  }

  /**
   * 检查歌曲是否已下载
   */
  async isDownloaded(songId: string): Promise<boolean> {
    try {
      const downloads = await this.getDownloads();
      return downloads.includes(songId);
    } catch (error) {
      console.error('检查下载状态失败:', error);
      return false;
    }
  }
}
