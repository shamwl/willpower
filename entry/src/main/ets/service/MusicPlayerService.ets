import promptAction from '@ohos.promptAction';
import media from '@ohos.multimedia.media';
import { Song, PlayState } from '../model/SongModel';
import common from '@ohos.app.ability.common';

/**
 * 音乐播放服务
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

  // 监听器
  onStateChangeListener?: (state: PlayState) => void;
  onProgressChangeListener?: (currentTime: number, duration: number) => void;
  onSongChangeListener?: (song: Song) => void;
  onErrorListener?: (errorMsg: string) => void;

  private constructor() {}

  private setPlayState(newState: PlayState): void {
    this.playState = newState;
    if (this.onStateChangeListener) {
      this.onStateChangeListener(newState);
    }
  }

  private setCurrentSong(song: Song): void {
    this.currentSong = song;
    if (this.onSongChangeListener) {
      this.onSongChangeListener(song);
    }
  }

  private updateProgress(currentTime: number, duration: number): void {
    this.progress = currentTime;
    this.duration = duration;
    if (this.onProgressChangeListener) {
      this.onProgressChangeListener(currentTime, duration);
    }
  }

  private handleError(errorMsg: string): void {
    console.error(errorMsg);
    if (this.onErrorListener) {
      this.onErrorListener(errorMsg);
    }
  }

  public static getInstance(): MusicPlayerService {
    if (!MusicPlayerService.instance) {
      MusicPlayerService.instance = new MusicPlayerService();
    }
    return MusicPlayerService.instance;
  }

  public init(context: common.Context): void {
    this.context = context;
  }

  /**
   * 播放指定歌曲（在线播放）
   */
  public async play(song: Song): Promise<void> {
    console.info('========== 开始播放 ==========');
    console.info(`歌曲: ${song.name}`);
    console.info(`URL: ${song.ossPath}`);
    
    try {
      // 验证 URL
      if (!song.ossPath) {
        throw new Error('歌曲URL为空');
      }
      if (!song.ossPath.startsWith('http://') && !song.ossPath.startsWith('https://')) {
        throw new Error('无效的URL格式');
      }

      this.setCurrentSong(song);
      this.setPlayState(PlayState.LOADING);
      promptAction.showToast({ message: `🎵 正在加载: ${song.name}` });

      // 重置播放器
      await this.resetPlayer();

      // 创建新播放器
      const player = await media.createAVPlayer();
      console.info('播放器创建成功');

      // 设置回调
      player.on('error', (err: Error) => {
        console.error(`播放器错误: ${err.message}`);
        this.setPlayState(PlayState.ERROR);
        this.handleError('播放失败: ' + err.message);
      });

      player.on('stateChange', (state: string) => {
        console.info(`播放器状态: ${state}`);
        switch (state) {
          case 'initialized':
            console.info('已初始化，开始准备...');
            player.prepare();
            break;
          case 'prepared':
            console.info('准备完成，开始播放...');
            player.play();
            break;
          case 'playing':
            console.info('正在播放');
            this.setPlayState(PlayState.PLAYING);
            break;
          case 'paused':
            this.setPlayState(PlayState.PAUSED);
            break;
          case 'completed':
            this.setPlayState(PlayState.IDLE);
            this.playNext();
            break;
        }
      });

      player.on('timeUpdate', () => {
        const currentTime = player.currentTime * 1000;
        const duration = player.duration * 1000;
        this.updateProgress(currentTime, duration);
      });

      this.audioPlayer = player;

      // 设置播放源
      console.info('设置播放源...');
      player.url = song.ossPath;

    } catch (error) {
      console.error(`播放失败: ${(error as Error).message}`);
      this.setPlayState(PlayState.ERROR);
      this.handleError(`播放失败: ${(error as Error).message}`);
    }
  }

  /**
   * 重置播放器
   */
  private async resetPlayer(): Promise<void> {
    if (this.audioPlayer) {
      try {
        console.info('重置播放器...');
        this.audioPlayer.off('error');
        this.audioPlayer.off('stateChange');
        this.audioPlayer.off('timeUpdate');
        await this.audioPlayer.release();
        this.audioPlayer = null;
        console.info('播放器已重置');
      } catch (e) {
        console.warn(`重置播放器失败: ${(e as Error).message}`);
        this.audioPlayer = null;
      }
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    if (this.audioPlayer && this.playState === PlayState.PLAYING) {
      await this.audioPlayer.pause();
      this.setPlayState(PlayState.PAUSED);
    }
  }

  /**
   * 恢复播放
   */
  public async resume(): Promise<void> {
    if (this.audioPlayer && this.playState === PlayState.PAUSED) {
      await this.audioPlayer.play();
      this.setPlayState(PlayState.PLAYING);
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    if (this.audioPlayer) {
      await this.audioPlayer.stop();
      this.setPlayState(PlayState.IDLE);
    }
  }

  /**
   * 播放上一首
   */
  public async playPrev(): Promise<void> {
    if (this.playlist.length > 0) {
      this.currentIndex = (this.currentIndex - 1 + this.playlist.length) % this.playlist.length;
      await this.play(this.playlist[this.currentIndex]);
    }
  }

  /**
   * 播放上一首（兼容旧版方法名）
   */
  public async playPrevious(): Promise<void> {
    await this.playPrev();
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
   * 跳转到指定位置
   */
  public async seek(position: number): Promise<void> {
    if (this.audioPlayer) {
      try {
        // position 是百分比 (0-100)，需要转换为秒
        const targetTime = (position / 100) * this.duration / 1000;
        await this.audioPlayer.seek(targetTime);
      } catch (e) {
        console.warn(`跳转失败: ${(e as Error).message}`);
      }
    }
  }

  /**
   * 设置播放列表
   */
  public setPlaylist(playlist: Song[], startIndex: number = 0): void {
    this.playlist = playlist;
    this.currentIndex = startIndex;
  }

  /**
   * 获取播放状态
   */
  public getState(): PlayState {
    return this.playState;
  }

  /**
   * 获取当前歌曲
   */
  public getCurrentSong(): Song | null {
    return this.currentSong;
  }
}
