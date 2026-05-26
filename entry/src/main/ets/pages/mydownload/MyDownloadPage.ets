import router from '@ohos.router';
import { Song } from '../../model/SongModel'
import { PreferencesService } from '../../service/PreferencesService'
import { SongService } from '../../service/SongService'

/**
 * 我的下载页面
 * 包含收藏和下载两个子页面
 */
@Component
export struct MyDownloadPage {
  @State currentTab: number = 0
  private tabs: string[] = ['我的收藏', '我的下载']

  build() {
    Column() {
      // 标题
      Text('我的音乐')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 15 })

      // Tab切换
      Row() {
        ForEach(this.tabs, (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(18)
              .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === index ? '#FF6B6B' : '#666666')
              .padding({ bottom: 8 })

            // 下划线
            Divider()
              .width(50)
              .strokeWidth(this.currentTab === index ? 3 : 0)
              .color('#FF6B6B')
          }
          .flexGrow(1)
          .onClick(() => {
            this.currentTab = index
          })
        })
      }
      .width('100%')
      .padding({ left: 40, right: 40 })

      Divider()
        .width('100%')
        .strokeWidth(1)
        .color('#EEEEEE')

      // Tab内容
      if (this.currentTab === 0) {
        FavoritesView()
      } else {
        DownloadsView()
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

/**
 * 收藏视图
 */
@Component
struct FavoritesView {
  @State favoriteSongs: Song[] = []
  private preferencesService: PreferencesService = PreferencesService.getInstance()
  private songService: SongService = SongService.getInstance()

  aboutToAppear() {
    this.loadFavorites()
  }

  /**
   * 加载收藏歌曲
   */
  async loadFavorites() {
    const favoriteIds: string[] = await this.preferencesService.getFavorites()
    const allSongs: Song[] = await this.songService.getSongList()
    this.favoriteSongs = allSongs.filter((song: Song) => favoriteIds.includes(song.id))
  }

  build() {
    Column() {
      if (this.favoriteSongs.length > 0) {
        // 收藏歌曲列表
        List() {
          ForEach(this.favoriteSongs, (song: Song, index: number) => {
            ListItem() {
              this.FavoriteSongItem(song, index)
            }
          })
        }
        .width('100%')
        .height('100%')
      } else {
        // 空状态
        Column() {
          Image($r('app.media.shamwl6'))
            .width(100)
            .height(100)
            .opacity(0.5)
          Text('暂无收藏歌曲')
            .fontSize(18)
            .fontColor('#999999')
            .margin({ top: 20 })
          Text('快去发现页收藏喜欢的歌曲吧')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
  }

  /**
   * 收藏歌曲项
   */
  @Builder
  FavoriteSongItem(song: Song, index: number) {
    Row() {
      // 歌曲封面（使用背景图作为占位）
      Image($r('app.media.music1'))
        .width(50)
        .height(50)
        .borderRadius(8)

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${song.author} - ${song.album}`)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      // 取消收藏按钮
      Text('❤️')
        .fontSize(20)
        .onClick(async () => {
          await this.preferencesService.removeFavorite(song.id)
          this.loadFavorites()
        })

      // 播放按钮
      Text('▶')
        .fontSize(20)
        .fontColor('#FF6B6B')
        .margin({ left: 15 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/player/PlayerPage',
            params: {
              songId: song.id
            }
          })
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/player/PlayerPage',
        params: {
          songId: song.id
        }
      })
    })
  }
}

/**
 * 下载视图
 */
@Component
struct DownloadsView {
  @State downloadedSongs: Song[] = []
  private preferencesService: PreferencesService = PreferencesService.getInstance()
  private songService: SongService = SongService.getInstance()

  aboutToAppear() {
    this.loadDownloads()
  }

  /**
   * 加载下载歌曲
   */
  async loadDownloads() {
    const downloadIds: string[] = await this.preferencesService.getDownloads()
    const allSongs: Song[] = await this.songService.getSongList()
    this.downloadedSongs = allSongs.filter((song: Song) => downloadIds.includes(song.id))
  }

  build() {
    Column() {
      if (this.downloadedSongs.length > 0) {
        // 下载歌曲列表
        List() {
          ForEach(this.downloadedSongs, (song: Song, index: number) => {
            ListItem() {
              this.DownloadSongItem(song, index)
            }
          })
        }
        .width('100%')
        .height('100%')
      } else {
        // 空状态
        Column() {
          Image($r('app.media.shamwl7'))
            .width(100)
            .height(100)
            .opacity(0.5)
          Text('暂无下载歌曲')
            .fontSize(18)
            .fontColor('#999999')
            .margin({ top: 20 })
          Text('快去播放歌曲进行下载吧')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
  }

  /**
   * 下载歌曲项
   */
  @Builder
  DownloadSongItem(song: Song, index: number) {
    Row() {
      // 歌曲封面（使用背景图作为占位）
      Image($r('app.media.music1'))
        .width(50)
        .height(50)
        .borderRadius(8)

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${song.author} - ${song.album}`)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        // 下载状态
        Row() {
          Text('✓')
            .fontSize(12)
            .fontColor('#52C41A')
          Text('已下载')
            .fontSize(10)
            .fontColor('#52C41A')
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      // 删除下载按钮
      Text('🗑️')
        .fontSize(20)
        .onClick(async () => {
          await this.preferencesService.removeDownload(song.id)
          this.loadDownloads()
        })

      // 播放按钮
      Text('▶')
        .fontSize(20)
        .fontColor('#FF6B6B')
        .margin({ left: 15 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/player/PlayerPage',
            params: {
              songId: song.id
            }
          })
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/player/PlayerPage',
        params: {
          songId: song.id
        }
      })
    })
  }
}