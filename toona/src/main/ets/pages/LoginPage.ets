import { ToastUtils } from '../utils/ToastUtils';
import { getThemeColors } from '../utils/ThemeManager';
import { LoginViewModel, LoginState } from '../viewmodels/LoginViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

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
  private viewModel: LoginViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new LoginViewModel(ServiceLocator.getAuthManager());

    const self = this;
    this.viewModel.setOnStateChanged((state: LoginState) => {
      self.homeserver = state.homeserver;
      self.userId = state.userId;
      self.password = state.password;
      self.isLoading = state.isLoading;
      self.errorMessage = state.errorMessage;
      self.rememberMe = state.rememberMe;
      self.isDiscovering = state.isDiscovering;
    });

    this.viewModel.setOnLoginSuccess(() => {
      if (self.pathStack) {
        self.pathStack.clear();
        const param: Record<string, Object> = {};
        self.pathStack.pushPathByName('MainPage', param);
      }
    });

    this.viewModel.setOnNavigateToRegister(() => {
      if (self.pathStack) {
        const param: Record<string, Object> = {};
        self.pathStack.pushPathByName('RegisterPage', param);
      }
    });

    this.viewModel.loadSavedCredentials();
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
                this.viewModel?.setHomeserver(value);
              });
            TextInput({ placeholder: ' 用户名', text: this.userId })
              .width('100%')
              .height(50)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(6)
              .margin({ bottom: 15 })
              .onChange((value: string) => {
                this.viewModel?.setUserId(value);
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
                this.viewModel?.setPassword(value);
              });
            Row() {
              Checkbox()
                .select(this.rememberMe)
                .selectedColor(getThemeColors().primary)
                .onChange((value: boolean) => {
                  this.viewModel?.setRememberMe(value);
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
                this.viewModel?.login();
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
                this.viewModel?.handleSSOLogin();
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
                ToastUtils.show('生物识别登录暂不可用', 2000);
              });

            Row() {
              Text('还没有账号？')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary);
              Text('注册')
                .fontSize(14)
                .fontColor(getThemeColors().primary)
                .onClick(() => {
                  this.viewModel?.navigateToRegister();
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
