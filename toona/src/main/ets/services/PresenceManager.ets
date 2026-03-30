import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  GetPresenceResponse,
  SetPresenceRequest,
  PresenceState,
  PresenceListResponse
} from '../models/MatrixTypes';

export class PresenceManager {
  private static instance: PresenceManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): PresenceManager {
    if (!PresenceManager.instance) {
      PresenceManager.instance = new PresenceManager();
    }
    return PresenceManager.instance;
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

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    try {
      return await this.ensureHttpClient().getPresence(userId);
    } catch (error) {
      console.error('Failed to get presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get presence: ${errMsg}`);
    }
  }

  async setPresence(userId: string, presence: PresenceState, statusMsg?: string): Promise<void> {
    try {
      const request: SetPresenceRequest = { presence: presence };
      if (statusMsg !== undefined) {
        request.status_msg = statusMsg;
      }
      await this.ensureHttpClient().setPresence(userId, request);
    } catch (error) {
      console.error('Failed to set presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set presence: ${errMsg}`);
    }
  }

  async setOnline(userId: string, statusMsg?: string): Promise<void> {
    await this.setPresence(userId, 'online', statusMsg);
  }

  async setOffline(userId: string): Promise<void> {
    await this.setPresence(userId, 'offline');
  }

  async setUnavailable(userId: string, statusMsg?: string): Promise<void> {
    await this.setPresence(userId, 'unavailable', statusMsg);
  }

  async getPresenceList(userIds: string[]): Promise<PresenceListResponse> {
    try {
      return await this.ensureHttpClient().getPresenceList(userIds);
    } catch (error) {
      console.error('Failed to get presence list:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get presence list: ${errMsg}`);
    }
  }
}