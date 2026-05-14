import { AppLogger } from '../utils/AppLogger';
import { Device, DevicesResponse, UpdateDeviceRequest } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { DeviceAuthData } from '../network/clients/DeviceHttpClient';
import { MatrixConfig, MatrixHttpClient } from '../network/MatrixHttpClient';

export class DeviceManager {
  private static instance: DeviceManager;
  private httpClient: MatrixHttpClient | null = null;
  private logger = AppLogger.getLogger(DeviceManager);

  private constructor() {
  }

  static getInstance(): DeviceManager {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DeviceManager();
    }
    return DeviceManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      this.httpClient = MatrixConfig.getInstance().getHttpClient();
    }
    return this.httpClient;
  }

  async getDevices(): Promise<DevicesResponse> {
    try {
      return await this.ensureHttpClient().getDevices();
    } catch (error) {
      this.logger.error('Failed to get devices:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get devices: ${errMsg}`);
    }
  }

  async getDevice(deviceId: string): Promise<Device> {
    try {
      return await this.ensureHttpClient().getDevice(deviceId);
    } catch (error) {
      this.logger.error('Failed to get device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get device: ${errMsg}`);
    }
  }

  async updateDevice(deviceId: string, displayName?: string): Promise<void> {
    const update: UpdateDeviceRequest = {};
    if (displayName !== undefined) {
      update.display_name = displayName;
    }
    try {
      await this.ensureHttpClient().updateDevice(deviceId, update);
    } catch (error) {
      this.logger.error('Failed to update device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update device: ${errMsg}`);
    }
  }

  // 修复单删方法
  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    try {
      await this.ensureHttpClient().deleteDevice(deviceId, authData);
    } catch (error) {
      // ✅ 修复：显式断言为 Error 类型
      throw error as Error;
    }
  }

  // 修复批量删除方法
  async deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    try {
      await this.ensureHttpClient().deleteDevices(deviceIds, authData);
    } catch (error) {
      // ✅ 修复：显式断言为 Error 类型
      throw error as Error;
    }
  }

  async renameDevice(deviceId: string, newDisplayName: string): Promise<void> {
    await this.updateDevice(deviceId, newDisplayName);
  }

  async getCurrentDevice(): Promise<Device | null> {
    const currentDeviceId: string | undefined = AuthManager.getInstance().getSession()?.deviceId;
    if (!currentDeviceId) {
      return null;
    }
    try {
      return await this.getDevice(currentDeviceId);
    } catch (error) {
      return null;
    }
  }
}