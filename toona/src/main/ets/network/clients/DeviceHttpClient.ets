import { BaseHttpClient } from './BaseHttpClient';
import { DeviceInfo } from '../../models/types/DeviceTypes';

export interface DeviceAuthData {
  auth: Record<string, string | object>;
}

export interface DevicesResponse {
  devices: DeviceInfo[];
}

// 兼容现有的 updateDevice 调用
export interface UpdateDeviceRequest {
  display_name?: string;
}

export class DeviceHttpClient extends BaseHttpClient {

  // ==========================================
  // 1. 基础设备管理模块 (包含 UIA)
  // ==========================================

  // ✅ 修复 Error 23: 恢复返回 DevicesResponse 类型
  async getDevices(): Promise<DevicesResponse> {
    return await this.get<DevicesResponse>('/devices');
  }

  async getDevice(deviceId: string): Promise<DeviceInfo> {
    return await this.get<DeviceInfo>(`/devices/${deviceId}`);
  }

  // ✅ 修复 Error 10: 允许接收 UpdateDeviceRequest 或 Record 对象
  async updateDevice(deviceId: string, request: UpdateDeviceRequest | Record<string, Object>): Promise<void> {
    await this.put<Record<string, Object>>(`/devices/${deviceId}`, request as Record<string, string | object>);
  }

  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    let payload: Record<string, string | object> | undefined = undefined;
    if (authData) {
      payload = { "auth": authData.auth as object };
    }
    await this.delete<Record<string, Object>>(`/devices/${deviceId}`, payload);
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

  // ==========================================
  // 2. 端到端加密 & 密钥备份模块 (✅ 恢复被误删的方法)
  // ==========================================

  async queryKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/query', request as Record<string, string | object>);
  }

  async uploadKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/upload', request as Record<string, string | object>);
  }

  async claimKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/claim', request as Record<string, string | object>);
  }

  async queryRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/query', request as Record<string, string | object>);
  }

  async uploadRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/keys', request as Record<string, string | object>);
  }

  async getRoomKeys(version?: string): Promise<Record<string, Object>> {
    const url = version ? `/room_keys/keys?version=${version}` : '/room_keys/keys';
    return await this.get<Record<string, Object>>(url);
  }

  async putRoomKeys(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.put<Record<string, Object>>(`/room_keys/keys?version=${version}`, request as Record<string, string | object>);
  }

  async getKeyBackupVersion(): Promise<Record<string, Object>> {
    return await this.get<Record<string, Object>>('/room_keys/version');
  }

  async putKeyBackupVersion(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.put<Record<string, Object>>(`/room_keys/version/${version}`, request as Record<string, string | object>);
  }

  async createKeyBackupVersion(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/version', request as Record<string, string | object>);
  }

  async deleteKeyBackupVersion(version: string): Promise<Record<string, Object>> {
    return await this.delete<Record<string, Object>>(`/room_keys/version/${version}`);
  }

  async uploadSignatures(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/signatures/upload', request as Record<string, string | object>);
  }
}