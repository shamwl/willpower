import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Song } from '../../model/SongModel'
import { MusicPlayerService } from '../../service/MusicPlayerService'
import { PreferencesService } from '../../service/PreferencesService'
import { SongService } from '../../service/SongService'

/**
 * 播放器页面
 */
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
  private songService: SongService = SongService.getInstance()

  aboutToAppear() {
    const params: Record<string, string> = router.getParams() as Record<string, string>
    if (params && params.songId) {
      this.loadSong(params.songId)
    }

    this.musicPlayer.onStateChangeListener((state: string) => {
      this.isPlaying = state === 'playing'
    })

    this.musicPlayer.onProgressChangeListener((progress: number, duration: number) => {
      this.progress = progress
      this.duration = duration
    })

    this.musicPlayer.onSongChangeListener((song: Song | null) => {
      this.currentSong = song
      if (song) {
        this.loadFavoriteStatus(song.id)
      }
    })

    this.musicPlayer.onErrorListener((error: string) => {
      promptAction.showToast({ message: error })
    })
  }

  async loadSong(songId: string) {
    const song: Song | undefined = this.songService.getSongById(songId)
    if (song) {
      this.currentSong = song
      await this.loadFavoriteStatus(songId)
      await this.loadDownloadStatus(songId)
      await this.loadLyrics(song)
    }
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

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 1000 / 60)
    const secs = Math.floor((seconds / 1000) % 60)
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  async togglePlay() {
    if (this.isPlaying) {
      await this.musicPlayer.pause()
    } else {
      if (this.currentSong) {
        await this.musicPlayer.play(this.currentSong)
      }
    }
  }

  previous() {
    this.musicPlayer.playPrevious()
  }

  next() {
    this.musicPlayer.playNext()
  }

  async onProgressChange(value: number) {
    await this.musicPlayer.seek(value)
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
