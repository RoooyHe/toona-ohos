import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { SecureStorage } from '../storage/SecureStorage';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { Context } from '@kit.AbilityKit';

interface WellKnownResponse {
  "m.homeserver": {
    "base_url": string;
  };
  "m.identity_server"?: {
    "base_url": string;
  };
}

@Entry
@Component
struct LoginPage {
  @State homeserver: string = '';
  @State userId: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State rememberMe: boolean = true;
  @State isDarkMode: boolean = false;
  @State isDiscovering: boolean = false;
  private authManager: AuthManager = AuthManager.getInstance();
  private secureStorage: SecureStorage = SecureStorage.getInstance();

  aboutToAppear() {
    const colorMode = AppStorage.get<number>('colorMode');
    this.isDarkMode = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    this.loadSavedCredentials();
  }

  getThemeColors() {
    return {
      bg: this.isDarkMode ? '#1a1a1a' : '#ffffff',
      text: this.isDarkMode ? '#ffffff' : '#333333',
      textSecondary: this.isDarkMode ? '#999999' : '#666666',
      inputBg: this.isDarkMode ? '#2a2a2a' : '#f5f5f5',
      primary: '#10a37f',
      error: '#e53935',
      divider: this.isDarkMode ? '#3a3a3a' : '#e0e0e0'
    };
  }

  async loadSavedCredentials() {
    try {
      await this.secureStorage.init(getContext(this) as Context);
      const savedHomeserver = await this.secureStorage.loadString('saved_homeserver');
      const savedUserId = await this.secureStorage.loadString('saved_user_id');
      const savedRemember = await this.secureStorage.loadBoolean('remember_me');

      if (savedRemember && savedHomeserver) {
        this.homeserver = savedHomeserver;
        this.rememberMe = true;
      }
      if (savedRemember && savedUserId) {
        this.userId = savedUserId;
        this.rememberMe = true;
      }
    } catch (error) {
      console.error('Failed to load saved credentials:', error);
    }
  }

  async saveCredentials() {
    if (this.rememberMe) {
      await this.secureStorage.saveString('saved_homeserver', this.homeserver);
      await this.secureStorage.saveString('saved_user_id', this.userId);
      await this.secureStorage.saveBoolean('remember_me', true);
    } else {
      await this.secureStorage.remove('saved_homeserver');
      await this.secureStorage.remove('saved_user_id');
      await this.secureStorage.saveBoolean('remember_me', false);
    }
  }

  async discoverHomeserver(domain: string): Promise<string | null> {
    const cleanDomain = domain.trim().toLowerCase();
    let serverUrl = cleanDomain;
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://' + serverUrl;
    }
    serverUrl = serverUrl.replace(/\/$/, '');

    try {
      const wellKnownUrl = serverUrl + '/.well-known/matrix/client';
      const response = await fetch(wellKnownUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        const data: WellKnownResponse = JSON.parse(JSON.stringify(response)) as WellKnownResponse;
        if (data && data['m.homeserver'] && data['m.homeserver'].base_url) {
          return data['m.homeserver'].base_url.replace(/\/$/, '');
        }
      }
    } catch (error) {
      console.warn('Well-known discovery failed, using direct connection:', error);
    }
    return serverUrl;
  }

  async handleLogin() {
    if (!this.homeserver || !this.userId || !this.password) {
      this.errorMessage = '请填写所有字段';
      return;
    }

    this.isDiscovering = true;
    this.errorMessage = '';
    this.isLoading = true;

    try {
      let serverUrl: string;
      if (this.homeserver.includes('.')) {
        serverUrl = await this.discoverHomeserver(this.homeserver) || this.homeserver;
      } else {
        serverUrl = this.homeserver.trim();
        if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
          serverUrl = 'https://' + serverUrl;
        }
        serverUrl = serverUrl.replace(/\/$/, '');
      }

      await this.authManager.setHomeserver(serverUrl);

      const isValidServer = await this.authManager.checkHomeserverVersion();
      if (!isValidServer) {
        this.errorMessage = '无法连接到服务器';
        this.isLoading = false;
        this.isDiscovering = false;
        return;
      }

      const session = await this.authManager.login(this.userId, this.password);

      await this.saveCredentials();

      promptAction.showToast({
        message: '登录成功',
        duration: 2000
      });

      router.replaceUrl({ url: 'pages/MainPage' }).catch(() => {
      });
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
      this.isDiscovering = false;
    }
  }

  handleRegister() {
    router.pushUrl({ url: 'pages/RegisterPage' }).catch(() => {
    });
  }

  handleSSOLogin() {
    promptAction.showToast({
      message: 'SSO登录需要配置身份提供商',
      duration: 2000
    });
  }

  toggleDarkMode() {
    this.isDarkMode = !this.isDarkMode;
    const newMode = this.isDarkMode ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    AppStorage.setOrCreate('colorMode', newMode);
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Text('Toona')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primary)
            .margin({ bottom: 10 });

          Text('Matrix 客户端')
            .fontSize(16)
            .fontColor(this.getThemeColors().textSecondary)
            .margin({ bottom: 60 });
        }
        .margin({ top: 60 });

        Column() {
          TextInput({ placeholder: ' homeserver (如: matrix.org)', text: this.homeserver })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(this.getThemeColors().inputBg)
            .borderRadius(10)
            .margin({ bottom: 15 })
            .onChange((value: string) => {
              this.homeserver = value;
            });

          TextInput({ placeholder: ' 用户名', text: this.userId })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(this.getThemeColors().inputBg)
            .borderRadius(10)
            .margin({ bottom: 15 })
            .onChange((value: string) => {
              this.userId = value;
            });

          TextInput({ placeholder: ' 密码', text: this.password })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(this.getThemeColors().inputBg)
            .borderRadius(10)
            .type(InputType.Password)
            .margin({ bottom: 10 })
            .onChange((value: string) => {
              this.password = value;
            });

          Row() {
            Checkbox()
              .select(this.rememberMe)
              .selectedColor(this.getThemeColors().primary)
              .onChange((value: boolean) => {
                this.rememberMe = value;
              });
            Text('记住我')
              .fontSize(14)
              .fontColor(this.getThemeColors().textSecondary)
              .margin({ left: 8 });
          }
          .width('100%')
          .margin({ bottom: 10 });

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor(this.getThemeColors().error)
              .margin({ bottom: 10 });
          }

          if (this.isDiscovering) {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(this.getThemeColors().primary);
              Text('正在发现服务器...')
                .fontSize(14)
                .fontColor(this.getThemeColors().textSecondary)
                .margin({ left: 8 });
            }
            .width('100%')
            .margin({ bottom: 10 });
          }

          Button(this.isLoading ? '登录中...' : '登录')
            .width('100%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.getThemeColors().primary)
            .borderRadius(10)
            .margin({ top: 10 })
            .enabled(!this.isLoading && !this.isDiscovering)
            .onClick(() => {
              this.handleLogin();
            });

          Row() {
            Line()
              .width('40%')
              .height(1)
              .backgroundColor(this.getThemeColors().divider);
            Text('或')
              .fontSize(12)
              .fontColor(this.getThemeColors().textSecondary)
              .margin({ left: 10, right: 10 });
            Line()
              .width('40%')
              .height(1)
              .backgroundColor(this.getThemeColors().divider);
          }
          .width('100%')
          .margin({ top: 15, bottom: 15 });

          Button('SSO 单点登录')
            .width('100%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.getThemeColors().bg)
            .fontColor(this.getThemeColors().primary)
            .borderRadius(10)
            .borderWidth(1)
            .borderColor(this.getThemeColors().primary)
            .enabled(!this.isLoading && !this.isDiscovering)
            .onClick(() => {
              this.handleSSOLogin();
            });

          Row() {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor(this.getThemeColors().textSecondary);
            Text('注册')
              .fontSize(14)
              .fontColor(this.getThemeColors().primary)
              .onClick(() => {
                this.handleRegister();
              });
          }
          .margin({ top: 20 });
        }
        .width('85%')
        .padding(20);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg);

      Column() {
        Row() {
          Image($r('app.media.menu'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain);
        }
        .width(40)
        .height(40)
        .backgroundColor(this.getThemeColors().bg)
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .shadow({
          radius: 4,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.toggleDarkMode();
        });
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Top)
      .padding({ right: 20, top: 20 });
    }
    .width('100%')
    .height('100%');
  }
}
