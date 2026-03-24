import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';

@Entry
@Component
struct RegisterPage {
  @State homeserver: string = '';
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private authManager: AuthManager = AuthManager.getInstance();

  aboutToAppear() {
    this.homeserver = this.authManager.getHomeserver() || '';
  }

  async handleRegister() {
    if (!this.homeserver || !this.username || !this.password || !this.confirmPassword) {
      this.errorMessage = '请填写所有字段';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次密码输入不一致';
      return;
    }

    if (this.password.length < 8) {
      this.errorMessage = '密码长度至少8位';
      return;
    }

    let serverUrl = this.homeserver.trim();
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://' + serverUrl;
    }
    serverUrl = serverUrl.replace(/\/$/, '');

    this.isLoading = true;
    this.errorMessage = '';

    try {
      if (serverUrl !== this.authManager.getHomeserver()) {
        await this.authManager.setHomeserver(serverUrl);
      }

      const isValidServer = await this.authManager.checkHomeserverVersion();
      if (!isValidServer) {
        this.errorMessage = '无法连接到服务器';
        return;
      }

      const session = await this.authManager.register(this.username, this.password);

      promptAction.showToast({
        message: '注册成功',
        duration: 2000
      });
      
      router.replaceUrl({ url: 'pages/MainPage' }).catch(() => {
        // TODO: Implement error handling.
      });
    } catch (error) {
      console.error('Registration failed:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      if (errorMsg.includes('M_USER_IN_USE')) {
        this.errorMessage = '用户名已被使用';
      } else if (errorMsg.includes('M_WEAK_PASSWORD')) {
        this.errorMessage = '密码强度不够';
      } else if (errorMsg.includes(':')) {
        const parts: string[] = errorMsg.split(':');
        this.errorMessage = parts[1] ? parts[1].trim() : errorMsg;
      } else {
        this.errorMessage = '注册失败，请检查服务器地址';
      }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Button('← 返回')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor('#10a37f')
          .onClick(() => {
            router.back();
          });
      }
      .width('85%')
      .margin({ top: 20, bottom: 40 });

      Column() {
        Text('创建账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 40 });

        TextInput({ placeholder: ' homeserver (如: matrix.org)' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .margin({ bottom: 15 })
          .textAlign(TextAlign.Start)
          .onChange((value: string) => {
            this.homeserver = value;
          });

        TextInput({ placeholder: ' 用户名' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .margin({ bottom: 15 })
          .onChange((value: string) => {
            this.username = value;
          });

        TextInput({ placeholder: ' 密码 (至少8位)' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .type(InputType.Password)
          .margin({ bottom: 15 })
          .onChange((value: string) => {
            this.password = value;
          });

        TextInput({ placeholder: ' 确认密码' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .type(InputType.Password)
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.confirmPassword = value;
          });

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#e53935')
            .margin({ bottom: 10 })
        }

        Button(this.isLoading ? '注册中...' : '注册')
          .width('100%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#10a37f')
          .borderRadius(10)
          .margin({ top: 20 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleRegister();
          });
      }
      .width('85%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
