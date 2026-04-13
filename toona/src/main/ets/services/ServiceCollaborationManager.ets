import { collaborationManager, collaborationInfo } from '@kit.CollaborationKit';
import { promptAction } from '@ohos.promptAction';
import { AsyncCallback, RemoteObject } from '@kit.AbilityKit';

export class ServiceCollaborationManager {
  private static instance: ServiceCollaborationManager;
  private isCollaborationEnabled: boolean = false;
  private collaborationList: collaborationInfo.DeviceInfo[] = [];

  static getInstance(): ServiceCollaborationManager {
    if (!ServiceCollaborationManager.instance) {
      ServiceCollaborationManager.instance = new ServiceCollaborationManager();
    }
    return ServiceCollaborationManager.instance;
  }

  async startCollaboration(): Promise<boolean> {
    try {
      const collaborationInfo: collaborationInfo.CollaborationInfo = {
        businessId: 'com.roy.toona.ohos',
        description: 'Toona Matrix Client'
      };

      const result = await collaborationManager.startCollaboration(collaborationInfo);
      this.isCollaborationEnabled = true;
      console.info('Collaboration started successfully');
      return result;
    } catch (error) {
      console.error('Failed to start collaboration: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async stopCollaboration(): Promise<void> {
    try {
      const collaborationInfo: collaborationInfo.CollaborationInfo = {
        businessId: 'com.roy.toona.ohos',
        description: 'Toona Matrix Client'
      };

      await collaborationManager.stopCollaboration(collaborationInfo);
      this.isCollaborationEnabled = false;
      console.info('Collaboration stopped successfully');
    } catch (error) {
      console.error('Failed to stop collaboration: %{public}s', JSON.stringify(error));
    }
  }

  async getCollaborationDevices(): Promise<collaborationInfo.DeviceInfo[]> {
    try {
      const collaborationInfo: collaborationInfo.CollaborationInfo = {
        businessId: 'com.roy.toona.ohos',
        description: 'Toona Matrix Client'
      };

      const result = await collaborationManager.getAvailableDevices(collaborationInfo);
      this.collaborationList = result || [];
      console.info(`Found ${this.collaborationList.length} collaborative devices`);
      return this.collaborationList;
    } catch (error) {
      console.error('Failed to get collaboration devices: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  async continueSession(targetDevice: collaborationInfo.DeviceInfo): Promise<boolean> {
    try {
      const collaborationInfo: collaborationInfo.CollaborationInfo = {
        businessId: 'com.roy.toona.ohos',
        description: 'Toona Matrix Client'
      };

      const sessionInfo: collaborationInfo.SessionInfo = {
        sourceDeviceId: '',
        targetDeviceId: targetDevice.networkId || '',
        sessionId: '',
        businessId: 'com.roy.toona.ohos'
      };

      await collaborationManager.continueSession(sessionInfo);
      promptAction.showToast({ message: '正在切换设备...' });
      return true;
    } catch (error) {
      console.error('Failed to continue session: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '设备切换失败' });
      return false;
    }
  }

  isEnabled(): boolean {
    return this.isCollaborationEnabled;
  }

  getDeviceCount(): number {
    return this.collaborationList.length;
  }

  async isCollaborationSupported(): Promise<boolean> {
    try {
      return collaborationManager.isCollaborationSupported();
    } catch (error) {
      console.error('Failed to check collaboration support: %{public}s', JSON.stringify(error));
      return false;
    }
  }
}