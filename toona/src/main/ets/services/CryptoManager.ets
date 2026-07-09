import { AppLogger } from '../utils/AppLogger';
import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
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
  UploadRoomKeysRoomsData,
  KeyBackupVersion,
  KeyBackupSessionData,
  SignatureRequest,
  SignatureResponse,
  DeviceKeyInfo
} from '../models/MatrixTypes';

export class CryptoManager {
  private static instance: CryptoManager;
  private httpClient: MatrixHttpClient | null = null;
  private logger = AppLogger.getLogger(CryptoManager);

  private constructor() {
  }

  static getInstance(): CryptoManager {
    if (!CryptoManager.instance) {
      CryptoManager.instance = new CryptoManager();
    }
    return CryptoManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('CryptoManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async queryDeviceKeys(userIds: string[], timeout?: number): Promise<QueryKeysResponse> {
    const request: QueryKeysRequest = {
      device_keys: {},
      timeout: timeout
    };
    for (let i: number = 0; i < userIds.length; i++) {
      request.device_keys![userIds[i]] = [];
    }
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().queryKeys(request as Object as Record<string, Object>);
      return result as QueryKeysResponse;
    } catch (error) {
      this.logger.error('Failed to query device keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to query device keys: ${errMsg}`);
    }
  }

  async uploadDeviceKeys(deviceKeys: Record<string, string | object>): Promise<UploadKeysResponse> {
    const deviceKeyInfo: DeviceKeyInfo = deviceKeys as Object as DeviceKeyInfo;
    const request: UploadKeysRequest = {
      device_keys: deviceKeyInfo
    };
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().uploadKeys(request as Object as Record<string, Object>);
      return result as Object as UploadKeysResponse;
    } catch (error) {
      this.logger.error('Failed to upload device keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload device keys: ${errMsg}`);
    }
  }

  async uploadOneTimeKeys(oneTimeKeys: Record<string, string>): Promise<UploadKeysResponse> {
    const request: UploadKeysRequest = {
      one_time_keys: oneTimeKeys
    };
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().uploadKeys(request as Object as Record<string, Object>);
      return result as UploadKeysResponse;
    } catch (error) {
      this.logger.error('Failed to upload one-time keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload one-time keys: ${errMsg}`);
    }
  }

  async uploadFallbackKeys(fallbackKeys: Record<string, string>): Promise<UploadKeysResponse> {
    const request: UploadKeysRequest = {
      fallback_keys: fallbackKeys
    };
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().uploadKeys(request as Object as Record<string, Object>);
      return result as UploadKeysResponse;
    } catch (error) {
      this.logger.error('Failed to upload fallback keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload fallback keys: ${errMsg}`);
    }
  }

  async claimKeys(requests: Record<string, Record<string, string>>, timeout?: number): Promise<ClaimKeysResponse> {
    const request: ClaimKeysRequest = {
      one_time_keys: requests,
      timeout: timeout
    };
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().claimKeys(request as Object as Record<string, Object>);
      return result as ClaimKeysResponse;
    } catch (error) {
      this.logger.error('Failed to claim keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to claim keys: ${errMsg}`);
    }
  }

  async queryRoomKeys(roomIds?: string[], sessionIds?: string[]): Promise<QueryRoomKeysResponse> {
    const request: QueryRoomKeysRequest = {};
    if (roomIds) {
      request.rooms = roomIds;
    }
    if (sessionIds) {
      request.session_ids = sessionIds;
    }
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().queryRoomKeys(request as Object as Record<string, Object>);
      return result as QueryRoomKeysResponse;
    } catch (error) {
      this.logger.error('Failed to query room keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to query room keys: ${errMsg}`);
    }
  }

  async uploadRoomKeys(roomsData: UploadRoomKeysRoomsData): Promise<UploadRoomKeysResponse> {
    const request: UploadRoomKeysRequest = {
      rooms: roomsData
    };
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().uploadRoomKeys(request as Object as Record<string, Object>);
      return result as UploadRoomKeysResponse;
    } catch (error) {
      this.logger.error('Failed to upload room keys:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload room keys: ${errMsg}`);
    }
  }

  async getRoomKeyBackup(version?: string): Promise<KeyBackupSessionData | null> {
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().getRoomKeys(version);
      return result as KeyBackupSessionData;
    } catch (error) {
      this.logger.error('Failed to get room key backup:', error);
      return null;
    }
  }

  async putRoomKeyBackup(version: string, data: KeyBackupSessionData): Promise<void> {
    try {
      await this.ensureHttpClient().putRoomKeys(version, data as Object as Record<string, Object>);
    } catch (error) {
      this.logger.error('Failed to put room key backup:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to put room key backup: ${errMsg}`);
    }
  }

  async getKeyBackupVersion(): Promise<KeyBackupVersion | null> {
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().getKeyBackupVersion();
      return result as Object as KeyBackupVersion;
    } catch (error) {
      this.logger.error('Failed to get key backup version:', error);
      return null;
    }
  }

  async createKeyBackupVersion(authData: Record<string, string | object>): Promise<string> {
    try {
      const response: Record<string, Object> = await this.ensureHttpClient().createKeyBackupVersion(authData as Object as Record<string, Object>);
      return response['version'] as string;
    } catch (error) {
      this.logger.error('Failed to create key backup version:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to create key backup version: ${errMsg}`);
    }
  }

  async updateKeyBackupVersion(version: string, authData: Record<string, string | object>): Promise<void> {
    try {
      await this.ensureHttpClient().putKeyBackupVersion(version, authData as Object as Record<string, Object>);
    } catch (error) {
      this.logger.error('Failed to update key backup version:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update key backup version: ${errMsg}`);
    }
  }

  async deleteKeyBackupVersion(version: string): Promise<void> {
    try {
      await this.ensureHttpClient().deleteKeyBackupVersion(version);
    } catch (error) {
      this.logger.error('Failed to delete key backup version:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete key backup version: ${errMsg}`);
    }
  }

  async uploadSignatures(request: SignatureRequest): Promise<SignatureResponse> {
    try {
      const result: Record<string, Object> = await this.ensureHttpClient().uploadSignatures(request as Object as Record<string, Object>);
      return result as SignatureResponse;
    } catch (error) {
      this.logger.error('Failed to upload signatures:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload signatures: ${errMsg}`);
    }
  }
}
