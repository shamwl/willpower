import router from '@ohos.router';

/**
 * 应用入口页面
 * 直接跳转到启动加载页面
 */
@Entry
@Component
struct Index {
  aboutToAppear() {
    // 直接跳转到启动加载页面
    router.replaceUrl({
      url: 'pages/StartLoadingPage'
    })
  }

  build() {
    Column() {
      Text('磊磊音乐')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}