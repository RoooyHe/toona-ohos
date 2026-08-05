import { AppLogger } from '../utils/AppLogger';
import {
  GetPresenceResponse,
  SetPresenceRequest,
  PresenceState,
  PresenceListResponse
} from '../models/MatrixTypes';
import { PresenceHttpClient } from '../network/clients/PresenceHttpClient';

export class PresenceManager {
  private presenceClient: PresenceHttpClient;
  private logger = AppLogger.getLogger(PresenceManager);

  constructor(presenceClient: PresenceHttpClient) {
    this.presenceClient = presenceClient;
  }

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    try {
      return await this.presenceClient.getPresence(userId);
    } catch (error) {
      this.logger.error('Failed to get presence:', error);
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
      await this.presenceClient.setPresence(userId, request);
    } catch (error) {
      this.logger.error('Failed to set presence:', error);
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
      return await this.presenceClient.getPresenceList(userIds);
    } catch (error) {
      this.logger.error('Failed to get presence list:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get presence list: ${errMsg}`);
    }
  }
}
