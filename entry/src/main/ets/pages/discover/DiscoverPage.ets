import router from '@ohos.router';
import { Song } from '../../model/SongModel'
import { SongService } from '../../service/SongService'

/**
 * 发现页面
 * 包含推荐和搜索两个子页面
 */
@Component
export struct DiscoverPage {
  @State currentTab: number = 0
  private tabs: string[] = ['推荐', '搜索']

  build() {
    Column() {
      // 标题
      Text('发现音乐')
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
              .width(40)
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
        RecommendedView()
      } else {
        SearchView()
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

/**
 * 推荐视图
 */
@Component
struct RecommendedView {
  @State recommendedSongs: Song[] = []
  private songService: SongService = SongService.getInstance()

  aboutToAppear() {
    this.loadRecommendedSongs()
  }

  /**
   * 加载推荐歌曲
   */
  async loadRecommendedSongs() {
    const allSongs: Song[] = await this.songService.getSongList()
    this.recommendedSongs = this.songService.getRandomRecommendations(20)
  }

  build() {
    Scroll() {
      Column() {
        // 推荐标题
        Text('每日推荐')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding({ left: 20, top: 20, bottom: 15 })

        // 推荐歌曲列表
        if (this.recommendedSongs.length > 0) {
          List() {
            ForEach(this.recommendedSongs, (song: Song, index: number) => {
              ListItem() {
                this.SongItem(song, index)
              }
            })
          }
          .width('100%')
          .height('100%')
        } else {
          // 加载中
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
            Text('加载推荐中...')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ top: 20 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
        }

      }
    }
  }

  /**
   * 歌曲列表项组件
   */
  @Builder
  SongItem(song: Song, index: number) {
    Row() {
      // 序号
      Text((index + 1).toString())
        .fontSize(16)
        .fontColor('#999999')
        .width(40)
        .textAlign(TextAlign.Center)

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

      // 播放按钮
      Text('▶')
        .fontSize(20)
        .fontColor('#FF6B6B')
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
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
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
 * 搜索视图
 */
@Component
struct SearchView {
  @State searchKeyword: string = ''
  @State searchResults: Song[] = []
  @State isSearching: boolean = false
  private songService: SongService = SongService.getInstance()

  build() {
    Column() {
      // 搜索框
      Search({
        placeholder: '搜索歌曲、歌手或专辑',
        value: this.searchKeyword
      })
        .width('90%')
        .height(45)
        .backgroundColor('#FFFFFF')
        .placeholderColor('#CCCCCC')
        .textFont({ size: 16 })
        .onChange((value: string) => {
          this.searchKeyword = value
          this.performSearch()
        })
        .margin({ top: 20, bottom: 20 })

      // 搜索结果
      if (this.isSearching) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('搜索中...')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 20 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)

      } else if (this.searchResults.length > 0) {
        // 搜索结果列表
        List() {
          ForEach(this.searchResults, (song: Song, index: number) => {
            ListItem() {
              this.SearchSongItem(song, index)
            }
          })
        }
        .width('100%')
        .height('100%')

      } else if (this.searchKeyword.trim() !== '') {
        // 无结果
        Column() {
          Text('🔍')
            .fontSize(80)
            .opacity(0.3)
          Text('未找到相关歌曲')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 20 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)

      } else {
        // 提示信息
        Column() {
          Text('输入关键词搜索歌曲')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      }

    }
  }

  /**
   * 执行搜索
   */
  async performSearch() {
    if (!this.searchKeyword.trim()) {
      this.searchResults = []
      return
    }

    this.isSearching = true

    // 延迟300ms，避免频繁搜索
    await this.delay(300)

    this.searchResults = this.songService.searchSongs(this.searchKeyword)
    this.isSearching = false
  }

  /**
   * 延迟函数
   */
  delay(ms: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, ms))
  }

  /**
   * 搜索结果歌曲项
   */
  @Builder
  SearchSongItem(song: Song, index: number) {
    Row() {
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

      // 播放按钮
      Text('▶')
        .fontSize(20)
        .fontColor('#FF6B6B')
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
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
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