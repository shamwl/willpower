import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
// 导入页面组件
import { DiscoverPage } from './discover/DiscoverPage'
import { MyDownloadPage } from './mydownload/MyDownloadPage'
import { PlayerPage } from './player/PlayerPage'
import { MyPage } from './my/MyPage'
import { PreferencesService } from '../service/PreferencesService'
import { MusicPlayerService } from '../service/MusicPlayerService'

/**
 * 主页面 - 底部导航
 * 包含4个主要页面：发现、我的下载、播放器、我的
 */
@Entry
@Component
struct MainTabs {
  @State currentIndex: number = 0
  private tabController: TabsController = new TabsController()
  private context: common.Context = getContext(this)

  aboutToAppear() {
    this.initServices()
  }

  async initServices() {
    try {
      PreferencesService.getInstance().init(this.context)
      MusicPlayerService.getInstance().init(this.context)
      console.info('服务初始化完成')
    } catch (error) {
      console.error('服务初始化失败:', error)
    }
  }

  build() {
    Tabs({
      index: this.currentIndex,
      controller: this.tabController,
      barPosition: BarPosition.End
    }) {
      // 发现页
      TabContent() {
        DiscoverPage()
      }
      .tabBar(this.TabBarItem('发现', $r('app.media.111'), 0))

      // 我的下载页
      TabContent() {
        MyDownloadPage()
      }
      .tabBar(this.TabBarItem('下载', $r('app.media.222'), 1))

      // 播放器页
      TabContent() {
        PlayerPage()
      }
      .tabBar(this.TabBarItem('播放', $r('app.media.333'), 2))

      // 我的页
      TabContent() {
        MyPage()
      }
      .tabBar(this.TabBarItem('我的', $r('app.media.444'), 3))
    }
    .width('100%')
    .height('100%')
    .barHeight(60)
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }

  /**
   * TabBar项
   */
  @Builder
  TabBarItem(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(26)
        .height(26)
        .objectFit(ImageFit.Contain)

      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#FF6B6B' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentIndex === index ? '#FFF5F5' : '#FFFFFF')
  }
}
