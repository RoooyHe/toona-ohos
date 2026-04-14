import { UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;

enum OnContinueResult {
  AGREE = 0,
  REJECT = 1,
  MISMATCH = 2
}

interface SessionData {
  timestamp: number;
  businessId: string;
}

export default class ToonaContinueAbility extends UIAbility {
  onContinue(wantParam: Record<string, Object>): OnContinueResult | Promise<OnContinueResult> {
    hilog.info(DOMAIN, 'ToonaContinue', 'onContinue called');
    
    const deviceType = wantParam?.['deviceType'] as string;
    const deviceName = wantParam?.['deviceName'] as string;
    const deviceId = wantParam?.['deviceId'] as string;
    
    hilog.info(DOMAIN, 'ToonaContinue', 'Continuing from device: %{public}s, type: %{public}s', 
      deviceName || 'unknown', deviceType || 'unknown');
    
    return OnContinueResult.AGREE;
  }

  onStartContinuation(): boolean {
    hilog.info(DOMAIN, 'ToonaContinue', 'onStartContinuation');
    return true;
  }

  onSaveData(want: Want): boolean {
    hilog.info(DOMAIN, 'ToonaContinue', 'onSaveData');
    
    want.parameters = want.parameters || {};
    want.parameters['sessionData'] = {
      "timestamp": Date.now(),
      "businessId": 'com.roy.toona.ohos'
    } as Record<string, Object>;
    
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
