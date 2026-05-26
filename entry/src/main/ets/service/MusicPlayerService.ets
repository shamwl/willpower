import fs from '@ohos.file.fs';
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { Song, PlayState, AppConfig, ProgressData } from '../model/SongModel';

/**
 * 音乐播放服务
 * 负责音频播放控制、OSS文件下载、播放器管理等
 */
export class MusicPlayerService {
  private static instance: MusicPlayerService;
  private currentSong: Song | null = null;
  private playState: PlayState = PlayState.IDLE;
  private playlist: Song[] = [];
  private currentIndex: number = 0;
  private progress: number = 0;
  private duration: number = 0;
  private context: common.Context | null = null;

  private onStateChange?: (state: PlayState) => void;
  private onProgressChange?: (progress: number, duration: number) => void;
  private onSongChange?: (song: Song | null) => void;
  private onError?: (error: string) => void;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): MusicPlayerService {
    if (!MusicPlayerService.instance) {
      MusicPlayerService.instance = new MusicPlayerService();
    }
    return MusicPlayerService.instance;
  }

  /**
   * 初始化
   */
  public init(context: common.Context): void {
    this.context = context;
  }

  /**
   * 播放指定歌曲
   */
  public async play(song: Song): Promise<void> {
    try {
      this.currentSong = song;
      this.playState = PlayState.LOADING;
      this.onStateChange?.(this.playState);
      this.onSongChange?.(song);

      promptAction.showToast({ message: `正在加载: ${song.name}` });

      const localPath = await this.downloadSongFromOSS(song);
      if (!localPath) {
        throw new Error('下载歌曲文件失败');
      }

      this.playState = PlayState.PLAYING;
      this.onStateChange?.(this.playState);
      this.duration = song.duration * 1000;

      promptAction.showToast({ message: `开始播放: ${song.name}` });

    } catch (error) {
      console.error('播放失败:', error);
      this.playState = PlayState.ERROR;
      this.onError?.('播放失败: ' + (error as Error).message);
    }
  }

  /**
   * 从OSS下载歌曲文件
   */
  private async downloadSongFromOSS(song: Song): Promise<string | null> {
    try {
      if (!this.context) {
        throw new Error('MusicPlayerService未初始化，请先调用init方法');
      }

      const ossUrl = `https://${AppConfig.OSS.bucket}.${AppConfig.OSS.endpoint}/${song.ossPath}`;
      console.info('开始下载歌曲:', ossUrl);

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(ossUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/octet-stream'
        }
      });

      if (response.responseCode === 200) {
        const tempDir = this.context.tempDir;
        const fileName = `${song.id}.mp3`;
        const filePath = `${tempDir}/${fileName}`;

        if (!fs.accessSync(tempDir)) {
          fs.mkdirSync(tempDir, true);
        }

        const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, response.result as ArrayBuffer);
        fs.closeSync(file);

        httpRequest.destroy();
        console.info('歌曲下载成功:', filePath);
        return filePath;
      } else {
        console.error('下载失败，HTTP状态码:', response.responseCode);
        httpRequest.destroy();
        return null;
      }
    } catch (error) {
      console.error('下载歌曲失败:', error);
      return null;
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    try {
      if (this.playState === PlayState.PLAYING) {
        this.playState = PlayState.PAUSED;
        this.onStateChange?.(this.playState);
        promptAction.showToast({ message: '已暂停' });
      }
    } catch (error) {
      console.error('暂停失败:', error);
      this.onError?.('暂停失败');
    }
  }

  /**
   * 恢复播放
   */
  public async resume(): Promise<void> {
    try {
      if (this.playState === PlayState.PAUSED) {
        this.playState = PlayState.PLAYING;
        this.onStateChange?.(this.playState);
        promptAction.showToast({ message: '继续播放' });
      }
    } catch (error) {
      console.error('恢复播放失败:', error);
      this.onError?.('恢复播放失败');
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    try {
      this.playState = PlayState.IDLE;
      this.onStateChange?.(this.playState);
    } catch (error) {
      console.error('停止播放失败:', error);
    }
  }

  /**
   * 跳转播放进度
   */
  public async seek(percent: number): Promise<void> {
    try {
      if (this.duration > 0) {
        const seekTime = Math.floor((percent / 100) * this.duration);
        this.progress = seekTime;
        this.onProgressChange?.(this.progress, this.duration);
        promptAction.showToast({ message: `已跳转至 ${Math.floor(seekTime / 1000)}秒` });
      }
    } catch (error) {
      console.error('跳转失败:', error);
      this.onError?.('跳转播放进度失败');
    }
  }

  /**
   * 播放上一首
   */
  public playPrevious(): void {
    if (this.playlist.length === 0) return;

    this.currentIndex = (this.currentIndex - 1 + this.playlist.length) % this.playlist.length;
    const song = this.playlist[this.currentIndex];
    this.play(song);
  }

  /**
   * 播放下一首
   */
  public playNext(): void {
    if (this.playlist.length === 0) return;

    this.currentIndex = (this.currentIndex + 1) % this.playlist.length;
    const song = this.playlist[this.currentIndex];
    this.play(song);
  }

  /**
   * 设置播放列表
   */
  public setPlaylist(songs: Song[], startIndex: number = 0): void {
    this.playlist = songs;
    this.currentIndex = startIndex;
    if (songs.length > 0) {
      this.play(songs[startIndex]);
    }
  }

  /**
   * 获取当前播放状态
   */
  public getPlayState(): PlayState {
    return this.playState;
  }

  /**
   * 获取当前歌曲
   */
  public getCurrentSong(): Song | null {
    return this.currentSong;
  }

  /**
   * 获取当前播放进度
   */
  public getProgress(): ProgressData {
    const data: ProgressData = {
      progress: this.progress,
      duration: this.duration
    };
    return data;
  }

  /**
   * 注册状态变化回调
   */
  public onStateChangeListener(callback: (state: PlayState) => void): void {
    this.onStateChange = callback;
  }

  /**
   * 注册进度变化回调
   */
  public onProgressChangeListener(callback: (progress: number, duration: number) => void): void {
    this.onProgressChange = callback;
  }

  /**
   * 注册歌曲变化回调
   */
  public onSongChangeListener(callback: (song: Song | null) => void): void {
    this.onSongChange = callback;
  }

  /**
   * 注册错误回调
   */
  public onErrorListener(callback: (error: string) => void): void {
    this.onError = callback;
  }

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    try {
      this.playState = PlayState.IDLE;
      this.currentSong = null;
    } catch (error) {
      console.error('释放资源失败:', error);
    }
  }
}
