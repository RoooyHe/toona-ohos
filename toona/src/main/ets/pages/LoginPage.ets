import { ToastUtils } from '../utils/ToastUtils';
import { UserAuthManager } from '../services/UserAuthManager';
import { getThemeColors } from '../utils/ThemeManager';
import { AppLogger } from '../utils/AppLogger';
import { ServiceLocator } from '../services/ServiceLocator';
import { IAuthManager, SavedCredentials } from '../services/AuthManager';

@Builder
export function LoginPageBuilder(name: string, param: Object) {
  LoginPage()
}

@Component
struct LoginPage {
  @StorageLink('colorMode') colorMode: number = 0;
  @State homeserver: string = '';
  @State userId: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State rememberMe: boolean = true;
  @State isDiscovering: boolean = false;
  private authManager: IAuthManager = ServiceLocator.getAuthManager();
  private userAuthManager: UserAuthManager = ServiceLocator.getUserAuthManager();
  private logger = AppLogger.getLogger(LoginPage);
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.loadSavedCredentials();
  }

  async loadSavedCredentials() {
    try {
      const creds = await this.authManager.loadSavedCredentials();
      if (creds && creds.rememberMe) {
        this.homeserver = creds.homeserver;
        this.userId = creds.userId;
        this.rememberMe = true;
      }
    } catch (error) {
      this.logger.error('Failed to load saved credentials:', error);
    }
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
        const discovered = await this.authManager.discoverHomeserverUrl(this.homeserver);
        serverUrl = discovered || this.homeserver;
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

      await this.authManager.login(this.userId, this.password);

      await this.authManager.saveCredentials(this.homeserver, this.userId, this.rememberMe);

      ToastUtils.show('登录成功', 2000);

      try {
        if (this.pathStack) {
          this.pathStack.clear();
          const param: Record<string, Object> = {};
          this.pathStack.pushPathByName('MainPage', param);
        }
      } catch (e) {
        this.logger.error('Navigation failed:', e);
      }
    } catch (error) {
      this.logger.error('Login failed:', error);
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
    if (this.pathStack) {
      const param: Record<string, Object> = {};
      this.pathStack.pushPathByName('RegisterPage', param);
    }
  }

  handleSSOLogin() {
    ToastUtils.show('SSO登录需要配置身份提供商', 2000);
  }

  async handleBiometricLogin() {
    try {
      const success = await this.userAuthManager.authenticateWithFace();
      if (success) {
        ToastUtils.show('验证成功，正在登录...');
        try {
          if (this.pathStack) {
            this.pathStack.clear();
            const param: Record<string, Object> = {};
            this.pathStack.pushPathByName('MainPage', param);
          }
        } catch (e) {
          this.logger.error('Navigation failed:', e);
        }
      }
    } catch (error) {
      this.logger.error('Biometric login failed: %{public}s', error.message);
      ToastUtils.show('生物识别登录失败');
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Column() {
            Text('Toona')
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().primary)
              .letterSpacing(-1.2)
              .margin({ bottom: 10 });
            Text('Matrix IM Client')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary)
              .margin({ bottom: 60 });
          }
          .margin({ top: 60 });

          Column() {
            TextInput({ placeholder: ' homeserver (如: matrix.org)', text: this.homeserver })
              .width('100%')
              .height(50)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(6)
              .margin({ bottom: 15 })
              .onChange((value: string) => {
                this.homeserver = value;
              });
            TextInput({ placeholder: ' 用户名', text: this.userId })
              .width('100%')
              .height(50)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(6)
              .margin({ bottom: 15 })
              .onChange((value: string) => {
                this.userId = value;
              });
            TextInput({ placeholder: ' 密码', text: this.password })
              .width('100%')
              .height(50)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(6)
              .type(InputType.Password)
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.password = value;
              });
            Row() {
              Checkbox()
                .select(this.rememberMe)
                .selectedColor(getThemeColors().primary)
                .onChange((value: boolean) => {
                  this.rememberMe = value;
                });
              Text('记住我')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary)
                .margin({ left: 8 });
            }
            .width('100%')
            .margin({ bottom: 10 });

            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor(getThemeColors().error)
                .margin({ bottom: 10 });
            }
            if (this.isDiscovering) {
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(getThemeColors().primary);
                Text('正在发现服务器...')
                  .fontSize(14)
                  .fontColor(getThemeColors().textSecondary)
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
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .borderRadius(6)
              .margin({ top: 10 })
              .enabled(!this.isLoading && !this.isDiscovering)
              .onClick(() => {
                this.handleLogin();
              });
            Row() {
              Line()
                .width('40%')
                .height(1)
                .backgroundColor(getThemeColors().divider);
              Text('或')
                .fontSize(12)
                .fontColor(getThemeColors().textSecondary)
                .margin({ left: 10, right: 10 });
              Line()
                .width('40%')
                .height(1)
                .backgroundColor(getThemeColors().divider);
            }
            .width('100%')
            .margin({ top: 15, bottom: 15 });

            Button('SSO 单点登录')
              .width('100%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(getThemeColors().bg)
              .fontColor(getThemeColors().primary)
              .borderRadius(6)
              .borderWidth(1)
              .borderColor(getThemeColors().dividerStrong)
              .enabled(!this.isLoading && !this.isDiscovering)
              .onClick(() => {
                this.handleSSOLogin();
              });

            Button('生物识别登录')
              .width('100%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .borderRadius(6)
              .margin({ top: 10 })
              .enabled(!this.isLoading && !this.isDiscovering)
              .onClick(() => {
                this.handleBiometricLogin();
              });

            Row() {
              Text('还没有账号？')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary);
              Text('注册')
                .fontSize(14)
                .fontColor(getThemeColors().primary)
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
        .backgroundColor(getThemeColors().bg);
      }
      .width('100%')
      .height('100%');
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true)
  }
}
