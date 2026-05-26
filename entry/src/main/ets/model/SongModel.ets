/**
 * 歌曲数据结构模型
 */
export interface Song {
  id: string;
  name: string;
  author: string;
  album: string;
  duration: number;
  ossPath: string;
  coverUrl?: string;
  lyrics?: string;
}

/**
 * 临时凭证数据结构
 */
export interface STSCredentials {
  accessKeyId: string;
  accessKeySecret: string;
  securityToken: string;
  expiration: string;
}

/**
 * 播放器状态枚举
 */
export enum PlayState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  ERROR = 'error'
}

/**
 * 用户信息数据结构
 */
export interface UserInfo {
  id: string;
  username: string;
  nickname: string;
  gender?: 'male' | 'female' | 'unknown';
  age?: number;
  birthday?: string;
  avatar?: string;
}

/**
 * 进度数据结构
 */
export interface ProgressData {
  progress: number;
  duration: number;
}

/**
 * 歌曲列表响应数据结构
 */
export interface SongListResponse {
  songs: SongDataItem[];
}

/**
 * 歌曲数据项结构
 */
export interface SongDataItem {
  id?: string;
  name?: string;
  author?: string;
  album?: string;
  duration?: number;
  ossPath?: string;
  coverUrl?: string;
  lyrics?: string;
}

/**
 * OSS配置接口
 */
export interface OSSConfig {
  region: string;
  endpoint: string;
  bucket: string;
  songFolder: string;
}

/**
 * Preferences配置接口
 */
export interface PreferencesConfig {
  FAVORITES: string;
  DOWNLOADS: string;
  USER_INFO: string;
}

/**
 * 应用配置接口
 */
export interface AppConfigInterface {
  BACKEND_URL: string;
  OSS: OSSConfig;
  SONG_LIST_URL: string;
  PREFERENCES: PreferencesConfig;
}

/**
 * 应用配置常量
 */
export const AppConfig: AppConfigInterface = {
  BACKEND_URL: 'http://localhost:3000',
  OSS: {
    region: 'cn-beijing',
    endpoint: 'oss-cn-beijing.aliyuncs.com',
    bucket: 'shamwl-project',
    songFolder: 'song'
  },
  SONG_LIST_URL: 'https://shamwl-project.oss-cn-beijing.aliyuncs.com/song-list.json',
  PREFERENCES: {
    FAVORITES: 'favorites',
    DOWNLOADS: 'downloads',
    USER_INFO: 'user_info'
  }
};
