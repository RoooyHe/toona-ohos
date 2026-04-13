import { UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { collaborationInfo } from '@kit.CollaborationKit';

const DOMAIN = 0x0001;

export default class ToonaContinueAbility extends UIAbility {
  onContinue(want: Want): void | collaborationInfo.OnContinueResult {
    hilog.info(DOMAIN, 'ToonaContinue', 'onContinue called');
    
    const deviceType = want.parameters?.['deviceType'] as string;
    const deviceName = want.parameters?.['deviceName'] as string;
    const deviceId = want.parameters?.['deviceId'] as string;
    
    hilog.info(DOMAIN, 'ToonaContinue', 'Continuing from device: %{public}s, type: %{public}s', 
      deviceName || 'unknown', deviceType || 'unknown');
    
    return collaborationInfo.OnContinueResult.AGREE;
  }

  onStartContinuation(): boolean {
    hilog.info(DOMAIN, 'ToonaContinue', 'onStartContinuation');
    return true;
  }

  onSaveData(want: Want): boolean {
    hilog.info(DOMAIN, 'ToonaContinue', 'onSaveData');
    
    want.parameters = want.parameters || {};
    want.parameters['sessionData'] = {
      timestamp: Date.now(),
      businessId: 'com.roy.toona.ohos'
    };
    
    return true;
  }

  onRestoreData(want: Want): void {
    hilog.info(DOMAIN, 'ToonaContinue', 'onRestoreData');
    
    const sessionData = want.parameters?.['sessionData'] as Record<string, Object>;
    if (sessionData) {
      hilog.info(DOMAIN, 'ToonaContinue', 'Restored session from: %{public}s', 
        JSON.stringify(sessionData));
    }
  }

  onCompleteContinuation(result: number): void {
    hilog.info(DOMAIN, 'ToonaContinue', 'onCompleteContinuation with result: %{public}d', result);
  }

  onFailedContinuation(code: number): void {
    hilog.error(DOMAIN, 'ToonaContinue', 'onFailedContinuation with code: %{public}d', code);
  }
}