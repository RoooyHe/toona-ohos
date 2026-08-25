import { AppLogger } from '../utils/AppLogger';
import { Device, DevicesResponse, UpdateDeviceRequest } from '../models/MatrixTypes';
import { AuthManager, IAuthManager } from './AuthManager';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

export interface DeviceAuthData {
  auth: Record<string, string | object>;
}

export interface IDeviceManager {
  getDevices(): Promise<DevicesResponse>;
  deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void>;
}

export class DeviceManager implements IDeviceManager {
  private logger = AppLogger.getLogger(DeviceManager);
  private authManager: IAuthManager;
  private baseClient: BaseHttpClient;

  constructor(authManager: IAuthManager, baseClient: BaseHttpClient) {
    this.authManager = authManager;
    this.baseClient = baseClient;
  }

  async getDevices(): Promise<DevicesResponse> {
    try {
      return await this.baseClient.get<DevicesResponse>('/devices');
    } catch (error) {
      this.logger.error('Failed to get devices:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get devices: ${errMsg}`);
    }
  }

  async getDevice(deviceId: string): Promise<Device> {
    try {
      const encodedDeviceId = this.baseClient.encodePath(deviceId);
      return await this.baseClient.get<Device>(`/devices/${encodedDeviceId}`);
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
      const encodedDeviceId = this.baseClient.encodePath(deviceId);
      await this.baseClient.put<Record<string, Object>>(`/devices/${encodedDeviceId}`, update as Record<string, string | object>);
    } catch (error) {
      this.logger.error('Failed to update device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update device: ${errMsg}`);
    }
  }

  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    try {
      const encodedDeviceId = this.baseClient.encodePath(deviceId);
      let payload: Record<string, string | object> | undefined = undefined;
      if (authData) {
        payload = { "auth": authData.auth as object };
      }
      await this.baseClient.delete<Record<string, Object>>(`/devices/${encodedDeviceId}`, payload);
    } catch (error) {
      throw error as Error;
    }
  }

  async deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    try {
      const payload: Record<string, string | object> = {
        "devices": deviceIds as Object
      };
      if (authData) {
        payload['auth'] = authData.auth as Object;
      }
      await this.baseClient.post<Record<string, Object>>('/delete_devices', payload);
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
