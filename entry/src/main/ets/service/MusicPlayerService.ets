import fs from '@ohos.file.fs';
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import media from '@ohos.multimedia.media';
import { Song, PlayState, AppConfig, ProgressData } from '../model/SongModel';

/**
 * 音乐播放服务
 * 使用新版 API 实现音频播放控制
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
  private audioPlayer: media.AVPlayer | null = null;

  // 定义监听器（可选属性，页面不注册就不会调用）
  onStateChangeListener?: (state: PlayState) => void;
  onProgressChangeListener?: (currentTime: number, duration: number) => void;
  onSongChangeListener?: (song: Song) => void;
  onErrorListener?: (errorMsg: string) => void;

  // 私有回调属性（用于兼容旧的 setCallbacks 方法）
  private onStateChange?: (state: PlayState) => void;
  private onProgressChange?: (progress: number, duration: number) => void;
  private onSongChange?: (song: Song | null) => void;
  private onError?: (error: string) => void;

  private constructor() {}

  /**
   * 设置播放状态并触发监听器
   */
  private setPlayState(newState: PlayState): void {
    this.playState = newState;
    if (this.onStateChangeListener) {
      this.onStateChangeListener(newState);
    }
  }

  /**
   * 设置当前歌曲并触发监听器
   */
  private setCurrentSong(song: Song): void {
    this.currentSong = song;
    if (this.onSongChangeListener) {
      this.onSongChangeListener(song);
    }
  }

  /**
   * 更新进度并触发监听器
   */
  private updateProgress(currentTime: number, duration: number): void {
    this.progress = currentTime;
    this.duration = duration;
    if (this.onProgressChangeListener) {
      this.onProgressChangeListener(currentTime, duration);
    }
  }

  /**
   * 处理错误并触发监听器
   */
  private handleError(errorMsg: string): void {
    console.error(errorMsg);
    if (this.onErrorListener) {
      this.onErrorListener(errorMsg);
    }
  }

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
   * 初始化服务
   */
  public init(context: common.Context): void {
    this.context = context;
  }

  /**
   * 设置回调函数
   */
  public setCallbacks(
    onStateChange?: (state: PlayState) => void,
    onProgressChange?: (progress: number, duration: number) => void,
    onSongChange?: (song: Song | null) => void,
    onError?: (error: string) => void
  ): void {
    this.onStateChange = onStateChange;
    this.onProgressChange = onProgressChange;
    this.onSongChange = onSongChange;
    this.onError = onError;
  }

  /**
   * 创建并配置音频播放器
   */
  private async createAndConfigurePlayer(): Promise<media.AVPlayer> {
    // 释放旧的播放器
    if (this.audioPlayer) {
      try {
        await this.audioPlayer.release();
      } catch (e) {
        console.warn('释放旧播放器失败:', e);
      }
      this.audioPlayer = null;
    }

    // 创建新的播放器
    const player: media.AVPlayer = await media.createAVPlayer();
    
    // 设置播放器回调
    player.on('error', (err: Error) => {
      this.setPlayState(PlayState.ERROR);
      this.handleError('播放失败: ' + err.message);
    });

    player.on('stateChange', (state: string) => {
      console.info(`播放器状态变化: ${state}`);
      switch (state) {
        case 'prepared':
          if (player.duration) {
            this.duration = player.duration * 1000;
          }
          break;
        case 'playing':
          this.setPlayState(PlayState.PLAYING);
          break;
        case 'paused':
          this.setPlayState(PlayState.PAUSED);
          break;
        case 'stopped':
          this.setPlayState(PlayState.IDLE);
          break;
        case 'completed':
          this.setPlayState(PlayState.IDLE);
          this.playNext();
          break;
      }
    });

    player.on('timeUpdate', () => {
      if (player) {
        const currentTime = player.currentTime * 1000;
        this.updateProgress(currentTime, this.duration);
      }
    });

    this.audioPlayer = player;
    return player;
  }

  /**
   * 播放指定歌曲
   */
  public async play(song: Song): Promise<void> {
    try {
      this.setCurrentSong(song);
      this.setPlayState(PlayState.LOADING);

      promptAction.showToast({ message: `🎵 正在加载: ${song.name}` });

      // 下载歌曲到本地
      const localPath = await this.downloadSongFromOSS(song);
      if (!localPath) {
        throw new Error('下载歌曲文件失败');
      }

      // 创建播放器
      const player = await this.createAndConfigurePlayer();
      
      // 设置播放源并准备播放（使用 prepare 方法传入 URI）
      const uri = `file://${localPath}`;
      console.info('设置播放源:', uri);
      player.url = uri;
      await player.prepare()
      
      // 开始播放
      player.play();

      promptAction.showToast({ message: `🎵 开始播放: ${song.name}` });

    } catch (error) {
      this.setPlayState(PlayState.ERROR);
      this.handleError('播放失败: ' + (error as Error).message);
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    try {
      if (this.playState === PlayState.PLAYING && this.audioPlayer) {
        await this.audioPlayer.pause();
        promptAction.showToast({ message: '⏸ 已暂停' });
      }
    } catch (error) {
      this.handleError('暂停失败');
    }
  }

  /**
   * 恢复播放
   */
  public async resume(): Promise<void> {
    try {
      if (this.playState === PlayState.PAUSED && this.audioPlayer) {
        await this.audioPlayer.play();
        promptAction.showToast({ message: '▶ 继续播放' });
      }
    } catch (error) {
      this.handleError('恢复播放失败');
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    try {
      if (this.audioPlayer) {
        await this.audioPlayer.stop();
      }
      this.setPlayState(PlayState.IDLE);
    } catch (error) {
      console.error('停止播放失败:', error);
    }
  }

  /**
   * 跳转播放进度
   */
  public seek(percent: number): void {
    try {
      if (this.duration > 0 && this.audioPlayer) {
        const seekTime = Math.floor((percent / 100) * this.duration) / 1000;
        this.audioPlayer.seek(seekTime);
        this.updateProgress(seekTime * 1000, this.duration);
        promptAction.showToast({ message: `⏩ 已跳转至 ${Math.floor(seekTime)}秒` });
      }
    } catch (error) {
      this.handleError('跳转播放进度失败');
    }
  }

  /**
   * 播放下一首
   */
  public async playNext(): Promise<void> {
    if (this.playlist.length > 0) {
      this.currentIndex = (this.currentIndex + 1) % this.playlist.length;
      await this.play(this.playlist[this.currentIndex]);
    }
  }

  /**
   * 播放上一首
   */
  public async playPrevious(): Promise<void> {
    if (this.playlist.length > 0) {
      this.currentIndex = (this.currentIndex - 1 + this.playlist.length) % this.playlist.length;
      await this.play(this.playlist[this.currentIndex]);
    }
  }

  /**
   * 设置播放列表
   */
  public setPlaylist(songs: Song[]): void {
    this.playlist = songs;
    this.currentIndex = 0;
  }

  /**
   * 获取当前播放状态
   */
  public getState(): PlayState {
    return this.playState;
  }

  /**
   * 获取当前播放歌曲
   */
  public getCurrentSong(): Song | null {
    return this.currentSong;
  }

  /**
   * 获取播放进度
   */
  public getProgress(): number {
    return this.progress;
  }

  /**
   * 获取歌曲时长
   */
  public getDuration(): number {
    return this.duration;
  }

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    try {
      if (this.audioPlayer) {
        await this.audioPlayer.release();
        this.audioPlayer = null;
      }
      this.playState = PlayState.IDLE;
      this.currentSong = null;
      this.progress = 0;
      this.duration = 0;
    } catch (error) {
      console.error('释放资源失败:', error);
    }
  }

  /**
   * 从 OSS 下载歌曲文件
   */
  private async downloadSongFromOSS(song: Song): Promise<string | null> {
    if (!this.context) {
      console.error('上下文未初始化');
      return null;
    }

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(song.ossPath, {
        method: http.RequestMethod.GET
      });

      if (response.responseCode === 200) {
        const cacheDir = this.context.cacheDir;
        const fileName = `${song.id}.mp3`;
        const filePath = `${cacheDir}/${fileName}`;

        // 写入文件
        const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, response.result as ArrayBuffer);
        fs.closeSync(file);

        return filePath;
      } else {
        console.error(`下载失败，HTTP 状态码: ${response.responseCode}`);
        return null;
      }
    } catch (error) {
      console.error('下载歌曲文件异常:', error);
      return null;
    }
  }
}