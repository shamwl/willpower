import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Song, PlayState } from '../../model/SongModel'
import { MusicPlayerService } from '../../service/MusicPlayerService'
import { PreferencesService } from '../../service/PreferencesService'

/**
 * 路由参数接口
 */
interface RouterParams {
  songId?: string;
  songName?: string;
  songUrl?: string;
}

/**
 * 播放器页面
 */
@Entry
@Component
export struct PlayerPage {
  @State currentSong: Song | null = null
  @State isPlaying: boolean = false
  @State progress: number = 0
  @State duration: number = 0
  @State isFavorite: boolean = false
  @State isDownloaded: boolean = false
  @State showLyrics: boolean = false
  @State currentLyrics: string = ''
  private musicPlayer: MusicPlayerService = MusicPlayerService.getInstance()
  private preferencesService: PreferencesService = PreferencesService.getInstance()

  aboutToAppear() {
    const params: RouterParams = router.getParams() as RouterParams
    
    // 支持两种参数传递方式：
    // 1. songId + songName + songUrl - 从 MyDownloadPage 传递（新方式）
    // 2. songName + songUrl - 从旧版 MyDownloadPage 传递（兼容模式）
    if (params && params.songId && params.songName && params.songUrl) {
      // 新方式：传递完整的歌曲信息
      this.loadSongByUrl(params.songId, params.songName, params.songUrl)
    } else if (params && params.songName && params.songUrl) {
      // 兼容模式：只传递 songName 和 songUrl
      this.loadSongByUrl(params.songName, params.songName, params.songUrl)
    }

    this.musicPlayer.onStateChangeListener = (state: PlayState) => {
      this.isPlaying = state === PlayState.PLAYING
    }

    this.musicPlayer.onProgressChangeListener = (currentTime: number, duration: number) => {
      this.progress = currentTime
      this.duration = duration
    }

    this.musicPlayer.onSongChangeListener = (song: Song) => {
      this.currentSong = song
      this.loadFavoriteStatus(song.id)
    }

    this.musicPlayer.onErrorListener = (errorMsg: string) => {
      promptAction.showToast({ message: errorMsg })
    }
  }

  async loadSongByUrl(songId: string, songName: string, songUrl: string) {
    // 从 songName 中提取艺术家和标题信息
    const formattedName = this.formatSongName(songName)
    const parts = formattedName.split('-')
    const author = parts.length >= 2 ? parts[0].trim() : '未知歌手'
    const title = parts.length >= 2 ? parts.slice(1).join('-').trim() : formattedName

    // 创建临时的 Song 对象，使用 songId 作为唯一标识
    this.currentSong = {
      id: songId,
      name: title,
      author: author,
      album: '未知专辑',
      duration: 0,
      ossPath: songUrl
    }
    
    await this.loadFavoriteStatus(songId)
    await this.loadDownloadStatus(songId)
    await this.loadLyrics(this.currentSong)
    
    // 调用播放器播放歌曲
    if (this.currentSong) {
      await this.musicPlayer.play(this.currentSong)
    }
  }

  formatSongName(name: string): string {
    let formatted = name.replace(/#[a-zA-Z0-9]+/g, '')
    formatted = formatted.replace(/\(.*版\)/g, '')
    formatted = formatted.replace(/\(.*remix\)/gi, '')
    formatted = formatted.replace(/\.Explicit\./gi, '.')
    formatted = formatted.replace(/\.[0-9]+x\./gi, '.')
    return formatted.trim()
  }

  async loadFavoriteStatus(songId: string) {
    this.isFavorite = await this.preferencesService.isFavorite(songId)
  }

  async loadDownloadStatus(songId: string) {
    this.isDownloaded = await this.preferencesService.isDownloaded(songId)
  }

  async loadLyrics(song: Song) {
    if (song.lyrics) {
      this.currentLyrics = song.lyrics
    } else {
      this.currentLyrics = '[00:00.00]暂无歌词'
    }
  }

  formatTime(milliseconds: number): string {
    const totalSeconds = Math.floor(milliseconds / 1000)
    const mins = Math.floor(totalSeconds / 60)
    const secs = totalSeconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  async togglePlay() {
    if (this.isPlaying) {
      await this.musicPlayer.pause()
    } else {
      // 检查当前播放状态
      const currentState = this.musicPlayer.getState()
      
      if (currentState === PlayState.PAUSED) {
        // 如果是暂停状态，调用 resume 恢复播放（不需要重新下载）
        await this.musicPlayer.resume()
      } else if (currentState === PlayState.IDLE || currentState === PlayState.LOADING || currentState === PlayState.ERROR) {
        // 如果是空闲、加载中或错误状态，重新播放当前歌曲
        if (this.currentSong) {
          await this.musicPlayer.play(this.currentSong)
        }
      }
      // 如果状态是 PLAYING，不需要操作（可能是状态同步延迟）
    }
  }

  previous() {
    this.musicPlayer.playPrevious()
  }

  next() {
    this.musicPlayer.playNext()
  }

  onProgressChange(value: number) {
    this.musicPlayer.seek(value)
  }

  async toggleFavorite() {
    if (!this.currentSong) return

    if (this.isFavorite) {
      await this.preferencesService.removeFavorite(this.currentSong.id)
      promptAction.showToast({ message: '已取消收藏' })
    } else {
      await this.preferencesService.addFavorite(this.currentSong.id)
      promptAction.showToast({ message: '已添加收藏' })
    }

    this.isFavorite = !this.isFavorite
  }

  async toggleDownload() {
    if (!this.currentSong) return

    if (!this.isDownloaded) {
      await this.preferencesService.addDownload(this.currentSong.id)
      this.isDownloaded = true
      promptAction.showToast({ message: '下载完成' })
    }
  }

  goBack() {
    router.back()
  }

  build() {
    Stack() {
      Image($r('app.media.music1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.4)

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')

      Column() {
        this.NavigationBar()

        if (this.showLyrics) {
          this.LyricsView()
        } else {
          this.AlbumView()
        }

        this.SongInfoView()
        this.ProgressView()
        this.ControlView()

      }
      .width('100%')
      .height('100%')

    }
    .width('100%')
    .height('100%')
  }

  @Builder
  NavigationBar() {
    Row() {
      Text('←')
        .fontSize(28)
        .fontColor('#FFFFFF')
        .onClick(() => this.goBack())

      Blank()

      Text(this.isFavorite ? '❤️' : '🤍')
        .fontSize(28)
        .onClick(() => this.toggleFavorite())

      Text('⬇️')
        .fontSize(28)
        .margin({ left: 20 })
        .onClick(() => this.toggleDownload())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 15 })
  }

  @Builder
  AlbumView() {
    Column() {
      Image($r('app.media.music1'))
        .width(280)
        .height(280)
        .borderRadius(20)
        .shadow({
          radius: 30,
          color: '#40000000',
          offsetX: 0,
          offsetY: 10
        })

      Text('点击查看歌词')
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ top: 20 })
        .onClick(() => {
          this.showLyrics = true
        })
    }
    .margin({ top: 40 })
  }

  @Builder
  LyricsView() {
    Column() {
      Scroll() {
        Text(this.currentLyrics)
          .fontSize(18)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .padding({ left: 30, right: 30 })
      }
      .width('100%')
      .height(280)
      .scrollBar(BarState.Off)

      Text('点击返回封面')
        .fontSize(14)
        .fontColor('#CCCCCC')
        .margin({ top: 20 })
        .onClick(() => {
          this.showLyrics = false
        })
    }
    .margin({ top: 40 })
  }

  @Builder
  SongInfoView() {
    Column() {
      Text(this.currentSong?.name || '未知歌曲')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)

      Text(this.currentSong?.author || '未知歌手')
        .fontSize(18)
        .fontColor('#CCCCCC')
        .margin({ top: 8 })

      Text(this.currentSong?.album || '未知专辑')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .margin({ top: 30 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProgressView() {
    Column() {
      Row() {
        Text(this.formatTime(this.progress))
          .fontSize(14)
          .fontColor('#FFFFFF')

        Slider({
          value: this.duration > 0 ? (this.progress / this.duration) * 100 : 0,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
          .width('75%')
          .blockColor('#FF6B6B')
          .trackColor('#FFFFFF33')
          .selectedColor('#FF6B6B')
          .onChange((value: number) => {
            this.onProgressChange(value)
          })

        Text(this.formatTime(this.duration))
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  @Builder
  ControlView() {
    Row() {
      Text('⏮')
        .fontSize(32)
        .onClick(() => this.previous())

      Blank()

      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(70)
          .height(70)
          .fill('#FF6B6B')
          .shadow({
            radius: 15,
            color: '#FF6B6B88',
            offsetX: 0,
            offsetY: 5
          })

        Text(this.isPlaying ? '⏸' : '▶')
          .fontSize(32)
          .onClick(() => this.togglePlay())
      }

      Blank()

      Text('⏭')
        .fontSize(32)
        .onClick(() => this.next())
    }
    .width('100%')
    .padding({ left: 40, right: 40, top: 30 })
  }
}
