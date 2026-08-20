import { getThemeColors } from '../utils/ThemeManager';
import { RegisterViewModel, RegisterState } from '../viewmodels/RegisterViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

@Builder
export function RegisterPageBuilder(name: string, param: Object) {
  RegisterPage()
}

@Component
struct RegisterPage {
  @State homeserver: string = '';
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  private viewModel: RegisterViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new RegisterViewModel(ServiceLocator.getAuthManager());

    const self = this;
    this.viewModel.setOnStateChanged((state: RegisterState) => {
      self.homeserver = state.homeserver;
      self.username = state.username;
      self.password = state.password;
      self.confirmPassword = state.confirmPassword;
      self.isLoading = state.isLoading;
      self.errorMessage = state.errorMessage;
    });

    this.viewModel.setOnRegisterSuccess(() => {
      if (self.pathStack) {
        self.pathStack.clear();
        const param: Record<string, Object> = {};
        self.pathStack.pushPathByName('MainPage', param);
      }
    });
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Button('← 返回')
            .fontSize(16)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().primary)
            .onClick(() => {
              this.pathStack.pop();
            });

          Blank();
        }
        .width('85%')
        .margin({ top: 20, bottom: 40 });

        Column() {
          Text('创建账号')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(getThemeColors().text)
            .letterSpacing(-0.42)
            .margin({ bottom: 40 });

          TextInput({ placeholder: ' homeserver (如: matrix.org)', text: this.homeserver })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .margin({ bottom: 15 })
            .textAlign(TextAlign.Start)
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.viewModel?.setHomeserver(value);
            });

          TextInput({ placeholder: ' 用户名' })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .margin({ bottom: 15 })
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.viewModel?.setUsername(value);
            });

          TextInput({ placeholder: ' 密码 (至少8位)' })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .type(InputType.Password)
            .margin({ bottom: 15 })
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.viewModel?.setPassword(value);
            });

          TextInput({ placeholder: ' 确认密码' })
            .width('100%')
            .height(50)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .type(InputType.Password)
            .margin({ bottom: 10 })
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.viewModel?.setConfirmPassword(value);
            });

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor(getThemeColors().error)
              .margin({ bottom: 10 });
          }

          Button(this.isLoading ? '注册中...' : '注册')
            .width('100%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(getThemeColors().primary)
            .fontColor(getThemeColors().onPrimary)
            .borderRadius(6)
            .margin({ top: 20 })
            .enabled(!this.isLoading)
            .onClick(() => {
              this.viewModel?.register();
            });
        }
        .width('85%')
        .padding(20);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .onReady((ctx) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
