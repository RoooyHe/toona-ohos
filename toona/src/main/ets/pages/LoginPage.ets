import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';

@Entry
@Component
struct LoginPage {
  @State homeserver: string = '';
  @State userId: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State hasSession: boolean = false;

  private authManager: AuthManager = AuthManager.getInstance();

  async aboutToAppear() {
    try {
      await this.authManager.init(getContext(this));
      const session = await this.authManager.restoreSession();
      if (session) {
        this.hasSession = true;
        router.replaceUrl({ url: 'pages/MainPage' });
      }
    } catch (error) {
      console.error('Init failed:', error);
    }
  }

  async handleLogin() {
    if (!this.homeserver || !this.userId || !this.password) {
      this.errorMessage = '请填写所有字段';
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
      await this.authManager.setHomeserver(serverUrl);
      
      const isValidServer = await this.authManager.checkHomeserverVersion();
      if (!isValidServer) {
        this.errorMessage = '无法连接到服务器';
        return;
      }

      const normalizedUserId = this.userId.startsWith('@') ? this.userId : `@${this.userId}`;
      
      const session = await this.authManager.login(normalizedUserId, this.password);
      
      promptAction.showToast({
        message: '登录成功',
        duration: 2000
      });
      
      router.replaceUrl({ url: 'pages/MainPage' });
    } catch (error) {
      console.error('Login failed:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      if (errorMsg.includes('M_FORBIDDEN')) {
        this.errorMessage = '用户名或密码错误';
      } else if (errorMsg.includes('M_USER_IN_USE')) {
        this.errorMessage = '用户已存在';
      } else if (errorMsg.includes(':')) {
        const parts: string[] = errorMsg.split(':');
        this.errorMessage = parts[1] ? parts[1].trim() : errorMsg;
      } else {
        this.errorMessage = '登录失败，请检查服务器地址';
      }
    } finally {
      this.isLoading = false;
    }
  }

  handleRegister() {
    router.pushUrl({ url: 'pages/RegisterPage' });
  }

  build() {
    Column() {
      Column() {
        Text('Toona')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor('#10a37f')
          .margin({ bottom: 10 });
        
        Text('Matrix 客户端')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 60 });
      }
      .margin({ top: 80 })

      Column() {
        TextInput({ placeholder: ' homeserver (如: matrix.org)' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .margin({ bottom: 15 })
          .onChange((value: string) => {
            this.homeserver = value;
          })

        TextInput({ placeholder: ' 用户名' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .margin({ bottom: 15 })
          .onChange((value: string) => {
            this.userId = value;
          })

        TextInput({ placeholder: ' 密码' })
          .width('100%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(10)
          .type(InputType.Password)
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.password = value;
          })

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#e53935')
            .margin({ bottom: 10 })
        }

        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#10a37f')
          .borderRadius(10)
          .margin({ top: 20 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          });

        Button('注册新账号')
          .width('100%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#ffffff')
          .fontColor('#10a37f')
          .borderRadius(10)
          .borderWidth(1)
          .borderColor('#10a37f')
          .margin({ top: 15 })
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
