import { AppLogger } from '../utils/AppLogger';
import { Device, DevicesResponse, UpdateDeviceRequest } from '../models/MatrixTypes';
import { AuthManager, IAuthManager } from './AuthManager';
import { DeviceAuthData, DeviceHttpClient } from '../network/clients/DeviceHttpClient';

export class DeviceManager {
  private deviceClient: DeviceHttpClient;
  private logger = AppLogger.getLogger(DeviceManager);
  private authManager: IAuthManager;

  constructor(authManager: IAuthManager, deviceClient: DeviceHttpClient) {
    this.authManager = authManager;
    this.deviceClient = deviceClient;
  }

  async getDevices(): Promise<DevicesResponse> {
    try {
      return await this.deviceClient.getDevices();
    } catch (error) {
      this.logger.error('Failed to get devices:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get devices: ${errMsg}`);
    }
  }

  async getDevice(deviceId: string): Promise<Device> {
    try {
      return await this.deviceClient.getDevice(deviceId);
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
      await this.deviceClient.updateDevice(deviceId, update);
    } catch (error) {
      this.logger.error('Failed to update device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update device: ${errMsg}`);
    }
  }

  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    try {
      await this.deviceClient.deleteDevice(deviceId, authData);
    } catch (error) {
      throw error as Error;
    }
  }

  async deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    try {
      await this.deviceClient.deleteDevices(deviceIds, authData);
    } catch (error) {
      throw error as Error;
    }
  }

  async renameDevice(deviceId: string, newDisplayName: string): Promise<void> {
    await this.updateDevice(deviceId, newDisplayName);
  }

  async getCurrentDevice(): Promise<Device | null> {
    const currentDeviceId: string | undefined = this.authManager.getSession()?.deviceId;
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
