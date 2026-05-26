import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

/**
 * 我的页面
 * 显示用户信息和登录注册功能
 */
@Component
export struct MyPage {
  @State isLoggedIn: boolean = false
  @State username: string = ''
  @State nickname: string = ''
  @State gender: string = 'unknown'
  @State age: number = 0
  @State birthday: string = ''

  aboutToAppear() {
    this.checkLoginStatus()
  }

  /**
   * 检查登录状态
   */
  async checkLoginStatus() {
    // 从本地存储获取用户信息
    // 这里简化处理，实际应该从PreferencesService获取
    this.isLoggedIn = false
  }

  build() {
    Column() {
      if (this.isLoggedIn) {
        // 已登录状态
        this.UserInfoView()
      } else {
        // 未登录状态
        this.LoginView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 用户信息视图
   */
  @Builder
  UserInfoView() {
    Column() {
      // 背景
      Image($r('app.media.shamwl5'))
        .width('100%')
        .height(280)
        .objectFit(ImageFit.Cover)

      // 用户信息卡片
      Column() {
        // 用户头像
        Image($r('app.media.music1'))
          .width(80)
          .height(80)
          .borderRadius(40)
          .borderWidth(3)
          .borderColor('#FFFFFF')
          .shadow({
            radius: 10,
            color: '#40000000',
            offsetX: 0,
            offsetY: 5
          })

        // 欢迎语
        Text('欢迎来到磊磊音乐，祝你天天开心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })

        // 用户信息
        Column() {
          this.InfoRow('用户名', this.username)
          Divider().width('100%').color('#EEEEEE')
          this.InfoRow('昵称', this.nickname)
          Divider().width('100%').color('#EEEEEE')
          this.InfoRow('性别', this.gender === 'male' ? '男' : (this.gender === 'female' ? '女' : '未知'))
          Divider().width('100%').color('#EEEEEE')
          this.InfoRow('年龄', this.age > 0 ? this.age.toString() : '未知')
          Divider().width('100%').color('#EEEEEE')
          this.InfoRow('生日', this.birthday || '未知')
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(15)
        .padding(20)
        .margin({ top: 20 })

        // 退出登录按钮
        Button('退出登录')
          .width('80%')
          .height(45)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B6B')
          .borderRadius(22)
          .margin({ top: 30 })
          .onClick(() => {
            this.isLoggedIn = false
            promptAction.showToast({ message: '已退出登录' })
          })

      }
      .margin({ top: -150 })

    }
    .width('100%')
    .height('100%')
  }

  /**
   * 信息行组件
   */
  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  /**
   * 登录视图
   */
  @Builder
  LoginView() {
    Column() {
      // 背景
      Image($r('app.media.shamwl5'))
        .width('100%')
        .height(350)
        .objectFit(ImageFit.Cover)

      // 欢迎语
      Column() {
        Text('磊磊音乐')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text('欢迎来到磊磊音乐，祝你天天开心')
          .fontSize(18)
          .fontColor('#666666')
          .margin({ top: 10 })

        // 登录按钮
        Button('登录')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B6B')
          .borderRadius(25)
          .margin({ top: 40 })
          .onClick(() => {
            this.showLoginDialog()
          })

        // 注册按钮
        Button('注册')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B6B')
          .backgroundColor('#FFFFFF')
          .borderWidth(2)
          .borderColor('#FF6B6B')
          .borderRadius(25)
          .margin({ top: 15 })
          .onClick(() => {
            this.showRegisterDialog()
          })

      }
      .margin({ top: 60 })

    }
    .width('100%')
    .height('100%')
  }

  /**
   * 显示登录对话框
   */
  showLoginDialog() {
    // 这里使用简单的方式，实际应该使用自定义弹窗
    promptAction.showToast({ message: '登录功能开发中...' })
  }

  /**
   * 显示注册对话框
   */
  showRegisterDialog() {
    // 这里使用简单的方式，实际应该使用自定义弹窗
    promptAction.showToast({ message: '注册功能开发中...' })
  }
}
