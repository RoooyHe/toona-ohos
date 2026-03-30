import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { Device, DevicesResponse, UpdateDeviceRequest } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';

export class DeviceManager {
  private static instance: DeviceManager;
  private httpClient: MatrixHttpClient | null = null;

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
      console.error('Failed to get devices:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get devices: ${errMsg}`);
    }
  }

  async getDevice(deviceId: string): Promise<Device> {
    try {
      return await this.ensureHttpClient().getDevice(deviceId);
    } catch (error) {
      console.error('Failed to get device:', error);
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
      console.error('Failed to update device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update device: ${errMsg}`);
    }
  }

  async deleteDevice(deviceId: string): Promise<void> {
    try {
      await this.ensureHttpClient().deleteDevice(deviceId);
    } catch (error) {
      console.error('Failed to delete device:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete device: ${errMsg}`);
    }
  }

  async deleteDevices(deviceIds: string[]): Promise<void> {
    try {
      await this.ensureHttpClient().deleteDevices(deviceIds);
    } catch (error) {
      console.error('Failed to delete devices:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete devices: ${errMsg}`);
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