import router from '@ohos.router';

/**
 * 启动加载页面
 */
@Entry
@Component
export struct StartLoadingPage {
  @State loadingText: string = '正在加载...'

  aboutToAppear() {
    console.info('StartLoadingPage aboutToAppear')
    setTimeout(() => {
      console.info('准备跳转到 MainTabs')
      router.replaceUrl({
        url: 'pages/MainTabs'
      })
    }, 2000)
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
        Text('WL音乐')
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
