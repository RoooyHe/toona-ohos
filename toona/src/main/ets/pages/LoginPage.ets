import { ToastUtils } from '../utils/ToastUtils';
import { SPHelper } from '@wondertek/wdkitlib';
import { UserAuthManager } from '../services/UserAuthManager';
import { getThemeColors } from '../utils/ThemeManager';
import http from '@ohos.net.http';
import { AppLogger } from '../utils/AppLogger';
import { ServiceRegistry } from '../services/ServiceRegistry';

function extractHomeServerUrl(jsonString: string): string | null {
  const regex = /"m\.homeserver"\s*:\s*\{\s*"base_url"\s*:\s*"([^"]+)"/;
  const match = jsonString.match(regex);
  if (match !== null && match[1] !== undefined) {
    return match[1];
  }
  return null;
}

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
  private userAuthManager: UserAuthManager = UserAuthManager.getInstance();
  private logger = AppLogger.getLogger(LoginPage);
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.loadSavedCredentials();
  }

  async loadSavedCredentials() {
    try {
      const savedHomeserver = await SPHelper.default.get('saved_homeserver', '') as string;
      const savedUserId = await SPHelper.default.get('saved_user_id', '') as string;
      const savedRemember = await SPHelper.default.get('remember_me', 'false') as string;

      if (savedRemember === 'true' && savedHomeserver) {
        this.homeserver = savedHomeserver;
        this.rememberMe = true;
      }
      if (savedRemember === 'true' && savedUserId) {
        this.userId = savedUserId;
        this.rememberMe = true;
      }
    } catch (error) {
      this.logger.error('Failed to load saved credentials:', error);
    }
  }

  async saveCredentials() {
    if (this.rememberMe) {
      await SPHelper.default.saveAndFlush('saved_homeserver', this.homeserver);
      await SPHelper.default.saveAndFlush('saved_user_id', this.userId);
      await SPHelper.default.saveAndFlush('remember_me', 'true');
    } else {
      await SPHelper.default.delete('saved_homeserver');
      await SPHelper.default.delete('saved_user_id');
      await SPHelper.default.saveAndFlush('remember_me', 'false');
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
      const httpClient = http.createHttp();
      const response = await httpClient.request(wellKnownUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Accept': 'application/json'
        }
      });

      if (response.responseCode === 200) {
        const responseData = response.result as string;
        const baseUrl = extractHomeServerUrl(responseData);
        if (baseUrl) {
          httpClient.destroy();
          return baseUrl.replace(/\/$/, '');
        }
      }
      httpClient.destroy();
    } catch (error) {
      this.logger.warn('Well-known discovery failed, using direct connection:', error);
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

      await ServiceRegistry.getCurrent().getAuthManager().setHomeserver(serverUrl);

      const isValidServer = await ServiceRegistry.getCurrent().getAuthManager().checkHomeserverVersion();
      if (!isValidServer) {
        this.errorMessage = '无法连接到服务器';
        this.isLoading = false;
        this.isDiscovering = false;
        return;
      }

      const session = await ServiceRegistry.getCurrent().getAuthManager().login(this.userId, this.password);

      await this.saveCredentials();

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
        await this.tryAutoLogin();
      }
    } catch (error) {
      this.logger.error('Biometric login failed: %{public}s', error.message);
      ToastUtils.show('生物识别登录失败');
    }
  }

  async tryAutoLogin() {
    try {
      const savedToken = await SPHelper.default.get('saved_access_token', '') as string;
      if (savedToken) {
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
      } else {
        ToastUtils.show('请先使用密码登录以启用生物识别');
      }
    } catch (error) {
      this.logger.error('Auto login failed: %{public}s', error.message);
      ToastUtils.show('自动登录失败');
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