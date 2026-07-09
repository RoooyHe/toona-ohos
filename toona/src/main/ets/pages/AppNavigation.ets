import { AuthManager } from '../services/AuthManager';
import { ConfigurationConstant } from '@kit.AbilityKit';

@Builder
export function AppNavigationBuilder(name: string, param: Object) {
  AppNavigation()
}

@Entry
@Component
struct AppNavigation {
  @StorageLink('colorMode') colorMode: number = 0;
  pathStack: NavPathStack = new NavPathStack();
  private authManager: AuthManager = AuthManager.getInstance();
  private hasNavigated: boolean = false;

  aboutToAppear() {
    AppStorage.setOrCreate('colorMode', ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    this.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  }

  onPageShow() {
    if (this.hasNavigated) {
      return;
    }
    this.hasNavigated = true;
    const session = this.authManager.getSession();
    if (session !== null) {
      this.pathStack.clear();
      const param: Record<string, Object> = {};
      this.pathStack.pushPathByName('MainPage', param);
    } else {
      this.pathStack.clear();
      const param: Record<string, Object> = {};
      this.pathStack.pushPathByName('LoginPage', param);
    }
  }

  build() {
    Navigation(this.pathStack) {
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }
}
