import router from '@ohos.router';
import { Song } from '../../model/SongModel'

/**
 * 资源管理器接口
 */
interface ResourceManagerInterface {
  getRawFileContent(fileName: string): Promise<ArrayBuffer>;
}

/**
 * 应用上下文接口
 */
interface AppContextInterface {
  resourceManager: ResourceManagerInterface;
}

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
 * 歌曲数据接口（与 MyDownloadPage 一致）
 */
interface SongItem {
  id: string;
  name: string;
  url: string;
}

/**
 * 推荐视图
 */
@Component
struct RecommendedView {
  @State recommendedSongs: Song[] = []

  aboutToAppear() {
    this.loadRecommendedSongs()
  }

  /**
   * 加载推荐歌曲（从 rawfile 读取）
   */
  async loadRecommendedSongs() {
    try {
      const appContext = getContext(this) as AppContextInterface
      const fileData: ArrayBuffer = await appContext.resourceManager.getRawFileContent('encoded_songs.json')
      const uint8Array: Uint8Array = new Uint8Array(fileData)
      const jsonString: string = this.uint8ArrayToString(uint8Array)
      const songItems: SongItem[] = JSON.parse(jsonString) as SongItem[]
      
      // 转换为 Song 类型并随机选取20首
      const allSongs: Song[] = songItems.map(item => {
        const song: Song = {
          id: item.id,
          name: this.formatSongName(item.name),
          author: this.getAuthor(item.name),
          album: '未知专辑',
          duration: 0,
          ossPath: item.url
        };
        return song;
      })
      
      // 随机打乱并取前20首
      this.recommendedSongs = allSongs.sort(() => Math.random() - 0.5).slice(0, 20)
    } catch (error) {
      console.error('加载推荐歌曲失败:', error)
    }
  }

  /**
   * 将 Uint8Array 转换为字符串
   */
  uint8ArrayToString(uint8Array: Uint8Array): string {
    let result: string = ''
    let i: number = 0
    while (i < uint8Array.length) {
      const byte: number = uint8Array[i]
      if (byte < 0x80) {
        result += String.fromCharCode(byte)
        i++
      } else if (byte >= 0xE0) {
        const codePoint: number = ((byte & 0x0F) << 12) | ((uint8Array[i + 1] & 0x3F) << 6) | (uint8Array[i + 2] & 0x3F)
        result += String.fromCodePoint(codePoint)
        i += 3
      } else {
        const codePoint: number = ((byte & 0x1F) << 6) | (uint8Array[i + 1] & 0x3F)
        result += String.fromCodePoint(codePoint)
        i += 2
      }
    }
    return result
  }

  /**
   * 格式化歌曲名称
   */
  formatSongName(name: string): string {
    let formatted = name.replace(/#[a-zA-Z0-9]+/g, '')
    formatted = formatted.replace(/\(.*版\)/g, '')
    formatted = formatted.replace(/\(.*remix\)/gi, '')
    formatted = formatted.replace(/\.Explicit\./gi, '.')
    formatted = formatted.replace(/\.[0-9]+x\./gi, '.')
    return formatted.trim()
  }

  /**
   * 从歌曲名中提取艺术家
   */
  getAuthor(name: string): string {
    const formatted = this.formatSongName(name)
    const parts = formatted.split('-')
    return parts.length >= 2 ? parts[0].trim() : '未知歌手'
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
              songId: song.id,
              songName: song.name,
              songUrl: song.ossPath
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
          songId: song.id,
          songName: song.name,
          songUrl: song.ossPath
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
  private allSongs: Song[] = []

  aboutToAppear() {
    this.loadAllSongs()
  }

  /**
   * 加载所有歌曲（从 rawfile 读取）
   */
  async loadAllSongs() {
    try {
      const appContext = getContext(this) as AppContextInterface
      const fileData: ArrayBuffer = await appContext.resourceManager.getRawFileContent('encoded_songs.json')
      const uint8Array: Uint8Array = new Uint8Array(fileData)
      const jsonString: string = this.uint8ArrayToString(uint8Array)
      const songItems: SongItem[] = JSON.parse(jsonString) as SongItem[]
      
      // 转换为 Song 类型
      this.allSongs = songItems.map(item => {
        const song: Song = {
          id: item.id,
          name: this.formatSongName(item.name),
          author: this.getAuthor(item.name),
          album: '未知专辑',
          duration: 0,
          ossPath: item.url
        };
        return song;
      })
    } catch (error) {
      console.error('加载歌曲列表失败:', error)
    }
  }

  /**
   * 将 Uint8Array 转换为字符串
   */
  uint8ArrayToString(uint8Array: Uint8Array): string {
    let result: string = ''
    let i: number = 0
    while (i < uint8Array.length) {
      const byte: number = uint8Array[i]
      if (byte < 0x80) {
        result += String.fromCharCode(byte)
        i++
      } else if (byte >= 0xE0) {
        const codePoint: number = ((byte & 0x0F) << 12) | ((uint8Array[i + 1] & 0x3F) << 6) | (uint8Array[i + 2] & 0x3F)
        result += String.fromCodePoint(codePoint)
        i += 3
      } else {
        const codePoint: number = ((byte & 0x1F) << 6) | (uint8Array[i + 1] & 0x3F)
        result += String.fromCodePoint(codePoint)
        i += 2
      }
    }
    return result
  }

  /**
   * 格式化歌曲名称
   */
  formatSongName(name: string): string {
    let formatted = name.replace(/#[a-zA-Z0-9]+/g, '')
    formatted = formatted.replace(/\(.*版\)/g, '')
    formatted = formatted.replace(/\(.*remix\)/gi, '')
    formatted = formatted.replace(/\.Explicit\./gi, '.')
    formatted = formatted.replace(/\.[0-9]+x\./gi, '.')
    return formatted.trim()
  }

  /**
   * 从歌曲名中提取艺术家
   */
  getAuthor(name: string): string {
    const formatted = this.formatSongName(name)
    const parts = formatted.split('-')
    return parts.length >= 2 ? parts[0].trim() : '未知歌手'
  }

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

    // 在本地歌曲列表中搜索
    const keyword = this.searchKeyword.toLowerCase()
    this.searchResults = this.allSongs.filter(song => 
      song.name.toLowerCase().includes(keyword) || 
      song.author.toLowerCase().includes(keyword)
    )
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
              songId: song.id,
              songName: song.name,
              songUrl: song.ossPath
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
          songId: song.id,
          songName: song.name,
          songUrl: song.ossPath
        }
      })
    })
  }
}