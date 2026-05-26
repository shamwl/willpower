import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

/**
 * 歌曲数据接口
 */
interface SongItem {
  id: string;
  name: string;
  url: string;
}

/**
 * 资源管理器接口
 */
interface ResourceManagerInterface {
  getRawFileContent(fileName: string): Promise<ArrayBuffer>;
}

/**
 * 上下文接口
 */
interface ContextInterface {
  resourceManager: ResourceManagerInterface;
}

/**
 * 下载页面
 * 使用颜文字图标，展示所有歌曲列表，支持点击播放
 */
@Component
export struct MyDownloadPage {
  @State songs: SongItem[] = []
  @State isLoading: boolean = true
  @State loadingError: boolean = false
  @State currentPlayingIndex: number = -1
  @State searchKeyword: string = ''
  @State filteredSongs: SongItem[] = []

  aboutToAppear() {
    this.loadSongList()
  }

  /**
   * 加载歌曲列表（从 rawfile 读取）
   */
  async loadSongList() {
    try {
      this.isLoading = true
      this.loadingError = false

      const appContext: ContextInterface = getContext(this) as ContextInterface
      const resManager: ResourceManagerInterface = appContext.resourceManager

      // 读取 rawfile 中的 encoded_songs.json
      const fileData: ArrayBuffer = await resManager.getRawFileContent('encoded_songs.json')
      const uint8Array: Uint8Array = new Uint8Array(fileData)
      const jsonString: string = this.uint8ArrayToString(uint8Array)
      this.songs = JSON.parse(jsonString) as SongItem[]

      this.filteredSongs = [...this.songs]
      this.isLoading = false

      console.info(`成功加载 ${this.songs.length} 首歌曲`)
    } catch (error) {
      console.error('加载歌曲列表失败:', error)
      this.loadingError = true
      this.isLoading = false
      promptAction.showToast({ message: '加载歌曲列表失败' })
    }
  }

  /**
   * 将 Uint8Array 转换为字符串（处理 UTF-8 编码）
   */
  uint8ArrayToString(uint8Array: Uint8Array): string {
    let result: string = ''
    let i: number = 0
    while (i < uint8Array.length) {
      const byte: number = uint8Array[i]
      if (byte < 0x80) {
        // 单字节 ASCII
        result += String.fromCharCode(byte)
        i++
      } else if (byte >= 0xE0 && byte < 0xF0) {
        // 三字节 UTF-8
        if (i + 2 < uint8Array.length) {
          const codePoint: number = ((byte & 0x0F) << 12) | 
                                   ((uint8Array[i + 1] & 0x3F) << 6) | 
                                   (uint8Array[i + 2] & 0x3F)
          result += String.fromCharCode(codePoint)
        }
        i += 3
      } else if (byte >= 0xC0 && byte < 0xE0) {
        // 双字节 UTF-8
        if (i + 1 < uint8Array.length) {
          const codePoint: number = ((byte & 0x1F) << 6) | 
                                   (uint8Array[i + 1] & 0x3F)
          result += String.fromCharCode(codePoint)
        }
        i += 2
      } else {
        // 其他情况
        result += String.fromCharCode(byte)
        i++
      }
    }
    return result
  }

  /**
   * 搜索歌曲
   */
  onSearchChange(value: string) {
    this.searchKeyword = value
    if (value.trim()) {
      const keyword = value.toLowerCase()
      this.filteredSongs = this.songs.filter((song: SongItem) =>
        song.name.toLowerCase().includes(keyword)
      )
    } else {
      this.filteredSongs = [...this.songs]
    }
  }

  /**
   * 播放歌曲
   */
  playSong(song: SongItem, index: number) {
    this.currentPlayingIndex = index
    promptAction.showToast({ message: `🎵 正在播放: ${song.name}` })

    router.pushUrl({
      url: 'pages/player/PlayerPage',
      params: {
        songId: song.id,
        songName: song.name,
        songUrl: song.url
      }
    })
  }

  /**
   * 格式化歌曲名称（移除特殊字符和ID）
   */
  formatSongName(name: string): string {
    // 移除URL中的ID部分，如 #xxx 或 #数字
    let formatted = name.replace(/#[a-zA-Z0-9]+/g, '')
    // 移除版本信息
    formatted = formatted.replace(/\(.*版\)/g, '')
    formatted = formatted.replace(/\(.*remix\)/gi, '')
    formatted = formatted.replace(/\.Explicit\./gi, '.')
    formatted = formatted.replace(/\.[0-9]+x\./gi, '.')
    return formatted.trim()
  }

  /**
   * 获取歌曲艺术家
   */
  getArtist(name: string): string {
    const formatted = this.formatSongName(name)
    const parts = formatted.split('-')
    if (parts.length >= 2) {
      return parts[0].trim()
    }
    return '未知歌手'
  }

  /**
   * 获取歌曲标题
   */
  getTitle(name: string): string {
    const formatted = this.formatSongName(name)
    const parts = formatted.split('-')
    if (parts.length >= 2) {
      return parts.slice(1).join('-').trim()
    }
    return formatted
  }

  build() {
    Column() {
      // 头部区域
      Column() {
        // 标题
        Row() {
          Text('🎵 音乐库')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(`(${this.songs.length}首)`)
            .fontSize(18)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ top: 20, left: 20 })

        // 搜索框
        Row() {
          Text('🔍')
            .fontSize(18)
            .margin({ left: 15 })
          TextInput({ placeholder: '搜索歌曲...' })
            .width('85%')
            .height(45)
            .backgroundColor('#F5F5F5')
            .borderRadius(22)
            .padding({ left: 10 })
            .onChange((value: string) => this.onSearchChange(value))
        }
        .width('90%')
        .height(45)
        .backgroundColor('#F5F5F5')
        .borderRadius(22)
        .margin({ top: 15 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 10,
        color: '#00000010',
        offsetY: 5
      })

      // 内容区域
      if (this.isLoading) {
        // 加载状态
        Column() {
          Text('⏳')
            .fontSize(48)
            .margin({ bottom: 15 })
          Text('正在加载音乐库...')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.loadingError) {
        // 错误状态
        Column() {
          Text('❌')
            .fontSize(48)
            .margin({ bottom: 15 })
          Text('加载失败，请重试')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 15 })
          Button('🔄 重新加载')
            .width(150)
            .height(45)
            .backgroundColor('#FF6B6B')
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .onClick(() => this.loadSongList())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredSongs.length === 0) {
        // 空状态
        Column() {
          Text('🔍')
            .fontSize(48)
            .margin({ bottom: 15 })
          Text('没有找到匹配的歌曲')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // 歌曲列表
        List() {
          ForEach(this.filteredSongs, (song: SongItem, index: number) => {
            ListItem() {
              this.SongItem(song, index)
            }
            .swipeAction({
              end: this.SwipeActions(song, index)
            })
          })
        }
        .width('100%')
        .height('100%')
        .divider({ strokeWidth: 0.5, color: '#EEEEEE' })
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }

  /**
   * 歌曲项
   */
  @Builder
  SongItem(song: SongItem, index: number) {
    Row() {
      // 序号/播放状态
      Column() {
        if (this.currentPlayingIndex === index) {
          Text('🎶')
            .fontSize(20)
            .animation({
              duration: 500,
              iterations: -1,
              curve: Curve.Linear
            })
        } else {
          Text(`${index + 1}`)
            .fontSize(18)
            .fontColor('#CCCCCC')
        }
      }
      .width(40)
      .height(60)
      .justifyContent(FlexAlign.Center)

      // 封面图标
      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Text('🎵')
            .fontSize(36)
        }
        .width(55)
        .height(55)
        .backgroundColor('#FF6B6B15')
        .borderRadius(12)

        if (this.currentPlayingIndex === index) {
          Circle()
            .width(12)
            .height(12)
            .fill('#FF6B6B')
            .position({ x: 40, y: 40 })
        }
      }

      // 歌曲信息
      Column() {
        Text(this.getTitle(song.name))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getArtist(song.name))
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      // 播放按钮
      Row() {
        Text(this.currentPlayingIndex === index ? '⏸' : '▶')
          .fontSize(22)
          .fontColor(this.currentPlayingIndex === index ? '#FF6B6B' : '#CCCCCC')
      }
      .width(45)
      .height(60)
      .justifyContent(FlexAlign.Center)

    }
    .width('100%')
    .height(70)
    .backgroundColor('#FFFFFF')
    .onClick(() => this.playSong(song, index))
  }

  /**
   * 滑动操作
   */
  @Builder
  SwipeActions(song: SongItem, index: number) {
    Row() {
      // 收藏
      Button('❤️')
        .width(70)
        .height('100%')
        .backgroundColor('#FFE4E4')
        .fontColor('#FF6B6B')
        .onClick(() => {
          promptAction.showToast({ message: `❤️ 已收藏: ${this.getTitle(song.name)}` })
        })

      // 分享
      Button('🔗')
        .width(70)
        .height('100%')
        .backgroundColor('#E4F0FF')
        .fontColor('#4A90E2')
        .onClick(() => {
          promptAction.showToast({ message: '🔗 分享链接已复制' })
        })
    }
    .height(70)
  }
}
