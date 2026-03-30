import {
  Device,
  DevicesResponse,
  UpdateDeviceRequest,
  QueryKeysRequest,
  QueryKeysResponse,
  UploadKeysRequest,
  UploadKeysResponse,
  ClaimKeysRequest,
  ClaimKeysResponse,
  QueryRoomKeysRequest,
  QueryRoomKeysResponse,
  UploadRoomKeysRequest,
  UploadRoomKeysResponse,
  KeyBackupVersion,
  KeyBackupSessionData,
  SignatureRequest,
  SignatureResponse
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

interface GeneratedTypeLiteralInterface_1 {
  version: string;
}

interface GeneratedTypeLiteralInterface_2 {
  version: string;
}

export class DeviceHttpClient extends BaseHttpClient {
  private toBody(obj: object): Record<string, string | object> {
    return JSON.parse(JSON.stringify(obj)) as Record<string, string | object>;
  }

  async getDevices(): Promise<DevicesResponse> {
    return await this.get<DevicesResponse>('/devices');
  }

  async getDevice(deviceId: string): Promise<Device> {
    const encodedDeviceId = encodeURIComponent(deviceId);
    return await this.get<Device>(`/devices/${encodedDeviceId}`);
  }

  async updateDevice(deviceId: string, update: UpdateDeviceRequest): Promise<void> {
    const encodedDeviceId = encodeURIComponent(deviceId);
    const body: Record<string, string | object> = {};
    if (update.display_name !== undefined) {
      body['display_name'] = update.display_name;
    }
    await this.put<void>(`/devices/${encodedDeviceId}`, body);
  }

  async deleteDevice(deviceId: string): Promise<void> {
    const encodedDeviceId = encodeURIComponent(deviceId);
    await this.delete<void>(`/devices/${encodedDeviceId}`);
  }

  async deleteDevices(deviceIds: string[]): Promise<void> {
    const body: Record<string, string | object> = { "device_ids": deviceIds };
    await this.post<void>('/delete_devices', body);
  }

  async queryKeys(request: QueryKeysRequest): Promise<QueryKeysResponse> {
    return await this.post<QueryKeysResponse>('/keys/query', this.toBody(request));
  }

  async uploadKeys(request: UploadKeysRequest): Promise<UploadKeysResponse> {
    return await this.post<UploadKeysResponse>('/keys/upload', this.toBody(request));
  }

  async claimKeys(request: ClaimKeysRequest): Promise<ClaimKeysResponse> {
    return await this.post<ClaimKeysResponse>('/keys/claim', this.toBody(request));
  }

  async queryRoomKeys(request: QueryRoomKeysRequest): Promise<QueryRoomKeysResponse> {
    return await this.post<QueryRoomKeysResponse>('/room/keys/query', this.toBody(request));
  }

  async uploadRoomKeys(request: UploadRoomKeysRequest): Promise<UploadRoomKeysResponse> {
    return await this.post<UploadRoomKeysResponse>('/room/keys/upload', this.toBody(request));
  }

  async getRoomKeys(roomId: string, sessionId: string): Promise<KeyBackupSessionData> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedSessionId = encodeURIComponent(sessionId);
    return await this.get<KeyBackupSessionData>(
      `/room/keys/keys/${encodedRoomId}/${encodedSessionId}`
    );
  }

  async putRoomKeys(roomId: string, sessionId: string, data: KeyBackupSessionData): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedSessionId = encodeURIComponent(sessionId);
    const body: Record<string, string | object> = {};
    if (data.first_message_index !== undefined) {
      body['first_message_index'] = String(data.first_message_index);
    }
    if (data.forwarded_count !== undefined) {
      body['forwarded_count'] = String(data.forwarded_count);
    }
    if (data.is_verified !== undefined) {
      body['is_verified'] = data.is_verified ? 'true' : 'false';
    }
    if (data.room_id !== undefined) {
      body['room_id'] = data.room_id;
    }
    if (data.session_id !== undefined) {
      body['session_id'] = data.session_id;
    }
    if (data.data !== undefined) {
      body['data'] = data.data;
    }
    await this.put<void>(`/room/keys/keys/${encodedRoomId}/${encodedSessionId}`, body);
  }

  async getKeyBackupVersion(): Promise<KeyBackupVersion | null> {
    try {
      return await this.get<KeyBackupVersion>('/room_keys/version');
    } catch (error) {
      if (error.message.includes('404')) {
        return null;
      }
      throw new Error(error.message);
    }
  }

  async putKeyBackupVersion(version: string, data: Record<string, string | object>): Promise<void> {
    await this.put<void>(
      `/room_keys/version/${encodeURIComponent(version)}`,
      data
    );
  }

  async createKeyBackupVersion(data: Record<string, string | object>): Promise<GeneratedTypeLiteralInterface_1> {
    return await this.post<GeneratedTypeLiteralInterface_2>('/room_keys/version', data);
  }

  async deleteKeyBackupVersion(version: string): Promise<void> {
    await this.delete<void>(
      `/room_keys/version/${encodeURIComponent(version)}`
    );
  }

  async uploadSignatures(request: SignatureRequest): Promise<SignatureResponse> {
    return await this.post<SignatureResponse>('/keys/signatures/upload', this.toBody(request));
  }
}
