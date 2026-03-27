import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AuthManager } from '../services/AuthManager';

const DOMAIN = 0x0000;

export default class ToonaAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onWindowStageCreate');

    const authManager = AuthManager.getInstance();

    authManager.init(this.context).then(async () => {
      hilog.info(DOMAIN, 'testTag', 'AuthManager init completed');

      const session = await authManager.restoreSession();
      hilog.info(DOMAIN, 'testTag', 'Session restore result: %{public}s', session ? 'success' : 'null');

      if (session) {
        windowStage.loadContent('pages/MainPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load MainPage. Cause: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, 'testTag', 'Succeeded in loading MainPage.');
        });
      } else {
        windowStage.loadContent('pages/LoginPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load LoginPage. Cause: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, 'testTag', 'Succeeded in loading LoginPage.');
        });
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'AuthManager init failed: %{public}s', err.message);
      windowStage.loadContent('pages/LoginPage', (loadErr) => {
        if (loadErr.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load LoginPage. Cause: %{public}s', JSON.stringify(loadErr));
          return;
        }
      });
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}