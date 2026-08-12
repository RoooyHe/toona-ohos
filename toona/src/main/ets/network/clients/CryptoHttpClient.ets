import { BaseHttpClient } from './BaseHttpClient';

export class CryptoHttpClient extends BaseHttpClient {
  async queryKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/query', request as Record<string, string | object>);
  }

  async uploadKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/upload', request as Record<string, string | object>);
  }

  async claimKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/claim', request as Record<string, string | object>);
  }

  async uploadSignatures(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/signatures/upload', request as Record<string, string | object>);
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
    const encodedVersion = this.encodePath(version);
    return await this.put<Record<string, Object>>(`/room_keys/version/${encodedVersion}`, request as Record<string, string | object>);
  }

  async createKeyBackupVersion(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/version', request as Record<string, string | object>);
  }

  async deleteKeyBackupVersion(version: string): Promise<Record<string, Object>> {
    const encodedVersion = this.encodePath(version);
    return await this.delete<Record<string, Object>>(`/room_keys/version/${encodedVersion}`);
  }
}
