import router from '@ohos.router';

/**
 * 启动加载页面
 * 应用启动时显示此页面，初始化完成后跳转到主页面
 */
@Entry
@Component
export struct StartLoadingPage {
  @State message: string = '磊磊音乐'
  @State loadingText: string = '正在加载...'
  private timerController: number = 0

  aboutToAppear() {
    // 模拟加载过程
    this.initApp()
  }

  /**
   * 初始化应用
   */
  async initApp() {
    try {
      // 显示加载状态
      this.loadingText = '正在初始化...'

      // 延迟1秒
      await this.delay(1000)
      this.loadingText = '正在加载歌曲列表...'

      // 延迟1秒
      await this.delay(1000)
      this.loadingText = '正在准备播放器...'

      // 延迟1秒
      await this.delay(1000)
      this.loadingText = '即将进入...'

      // 延迟1秒后跳转
      await this.delay(1000)

      // 跳转到主页
      router.replaceUrl({
        url: 'pages/MainTabs'
      })

    } catch (error) {
      console.error('初始化失败:', error)
      this.loadingText = '加载失败，请重试'
    }
  }

  /**
   * 延迟函数
   */
  delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  build() {
    Stack() {
      // 背景图片
      Image($r('app.media.music5'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.3)

      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')

      // 内容区域
      Column() {
        // 应用名称
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 30 })

        // 加载动画
        LoadingProgress()
          .width(60)
          .height(60)
          .color('#FFFFFF')
          .margin({ bottom: 20 })

        // 加载文本
        Text(this.loadingText)
          .fontSize(18)
          .fontColor('#CCCCCC')
          .textAlign(TextAlign.Center)

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

    }
    .width('100%')
    .height('100%')
  }
}
