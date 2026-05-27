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
          // 准备完成后自动播放
          console.info('播放器准备完成，开始播放');
          player.play().catch((e:Error) => {
            console.error('播放失败:', e);
            this.setPlayState(PlayState.ERROR);
            this.handleError('播放失败');
          });
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
    console.info('========== MusicPlayerService.play() 被调用 ==========');
    console.info(`歌曲名称: ${song.name}`);
    console.info(`歌曲ID: ${song.id}`);
    console.info(`歌曲URL: ${song.ossPath}`);
    
    try {
      // 检查上下文是否已初始化
      if (!this.context) {
        throw new Error('播放器服务未初始化，请先调用 init() 方法');
      }

      this.setCurrentSong(song);
      this.setPlayState(PlayState.LOADING);

      promptAction.showToast({ message: `🎵 正在加载: ${song.name}` });

      // 下载歌曲到本地
      console.info('步骤1: 开始下载歌曲...');
      const localPath = await this.downloadSongFromOSS(song);
      if (!localPath) {
        throw new Error('下载歌曲文件失败');
      }
      console.info(`步骤1完成: 歌曲已下载到 ${localPath}`);

      // 创建播放器
      console.info('步骤2: 创建音频播放器...');
      const player = await this.createAndConfigurePlayer();
      console.info('步骤2完成: 音频播放器创建成功');
      
      // 设置播放源并准备播放（使用新版 API）
      const uri = `file:///${localPath}`;
      console.info(`步骤3: 设置播放源: ${uri}`);

      // 设置播放源
      player.url = uri;

      // 发起准备（异步操作，后续由createAndConfigurePlayer中注册的stateChange回调处理）
      player.prepare();
      console.info('步骤3完成：已发起准备操作');

    } catch (error) {
      console.error(`========== MusicPlayerService.play() 失败 ==========`);
      console.error(`错误信息: ${(error as Error).message || (error as Object).toString()}`);
      this.setPlayState(PlayState.ERROR);
      this.handleError(`播放失败: ${(error as Error).message || '未知错误'}`);
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
    console.info('---------- downloadSongFromOSS 开始 ----------');
    console.info(`下载歌曲: ${song.name}`);
    console.info(`下载URL: ${song.ossPath}`);
    
    if (!this.context) {
      console.error('下载失败: 上下文未初始化');
      return null;
    }

    try {
      console.info('正在创建 HTTP 请求...');
      const httpRequest = http.createHttp();
      
      console.info('发送 GET 请求...');
      const response = await httpRequest.request(song.ossPath, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 30000
      });

      console.info(`HTTP响应状态码: ${response.responseCode}`);
      
      if (response.responseCode === 200 || response.responseCode === 304) {
        const cacheDir = this.context.cacheDir;
        const fileName = `${song.id}.mp3`;
        const filePath = `${cacheDir}/${fileName}`;
        
        console.info(`保存路径: ${filePath}`);

        // 处理响应数据
        let data: ArrayBuffer;
        const result: Object = response.result;
        if (typeof result === 'string') {
          console.info('响应数据是字符串类型');
          console.error('警告: 响应数据应为二进制类型，当前是字符串，可能导致播放失败');
          data = this.stringToArrayBuffer(result);
        } else if (result instanceof ArrayBuffer) {
          console.info('响应数据是 ArrayBuffer 类型');
          data = result;
        } else {
          console.error('下载失败: 无法解析响应数据');
          return null;
        }
        
        console.info(`文件大小: ${data.byteLength} bytes`);

        // 写入文件
        console.info('正在写入文件...');
        const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, data);
        fs.closeSync(file);
        
        console.info('---------- downloadSongFromOSS 成功 ----------');
        return filePath;
      } else {
        console.error(`下载失败，HTTP 状态码: ${response.responseCode}`);
        return null;
      }
    } catch (error) {
      console.error(`下载歌曲文件异常: ${(error as Object).toString()}`);
      return null;
    }
  }

  /**
   * 将字符串转换为 ArrayBuffer
   */
  private stringToArrayBuffer(str: string): ArrayBuffer {
    const buffer = new ArrayBuffer(str.length * 2);
    const view = new Uint16Array(buffer);
    for (let i = 0; i < str.length; i++) {
      view[i] = str.charCodeAt(i);
    }
    return buffer;
  }
}