import { Device, DevicesResponse, UpdateDeviceRequest } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export interface DeviceAuthData {
  auth: Record<string, string | object>;
}

export class DeviceHttpClient extends BaseHttpClient {
  async getDevices(): Promise<DevicesResponse> {
    return await this.get<DevicesResponse>('/devices');
  }

  async getDevice(deviceId: string): Promise<Device> {
    const encodedDeviceId = this.encodePath(deviceId);
    return await this.get<Device>(`/devices/${encodedDeviceId}`);
  }

  async updateDevice(deviceId: string, request: UpdateDeviceRequest | Record<string, Object>): Promise<void> {
    const encodedDeviceId = this.encodePath(deviceId);
    await this.put<Record<string, Object>>(`/devices/${encodedDeviceId}`, request as Record<string, string | object>);
  }

  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    const encodedDeviceId = this.encodePath(deviceId);
    let payload: Record<string, string | object> | undefined = undefined;
    if (authData) {
      payload = { "auth": authData.auth as object };
    }
    await this.delete<Record<string, Object>>(`/devices/${encodedDeviceId}`, payload);
  }

  async deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    const payload: Record<string, string | object> = {
      "devices": deviceIds as Object
    };
    if (authData) {
      payload['auth'] = authData.auth as Object;
    }
    await this.post<Record<string, Object>>('/delete_devices', payload);
  }
}
