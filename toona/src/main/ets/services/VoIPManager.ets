import { AppLogger } from '../utils/AppLogger';
import { VoipTurnServerResponse } from '../models/MatrixTypes';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

interface GeneratedTypeLiteralInterface_1 {
  uris: string[];
  username: string;
  credential: string;
}

export class VoIPManager {
  private logger = AppLogger.getLogger(VoIPManager);
  private httpClient: BaseHttpClient;

  constructor(httpClient: BaseHttpClient) {
    this.httpClient = httpClient;
  }

  async getTurnServer(): Promise<VoipTurnServerResponse> {
    try {
      return await this.httpClient.get<VoipTurnServerResponse>('/voip/turnServer');
    } catch (error) {
      this.logger.error('Failed to get TURN server:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get TURN server: ${errMsg}`);
    }
  }

  async getTurnCredentials(): Promise<GeneratedTypeLiteralInterface_1> {
    const response = await this.getTurnServer();
    if (!response.username || !response.credential) {
      throw new Error('TURN server response missing credentials');
    }
    return {
      uris: response.uris,
      username: response.username,
      credential: response.credential
    };
  }
}
