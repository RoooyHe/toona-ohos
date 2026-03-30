import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { VoipTurnServerResponse } from '../models/MatrixTypes';

interface GeneratedTypeLiteralInterface_1 {
  uris: string[];
  username: string;
  credential: string;
}

export class VoIPManager {
  private static instance: VoIPManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): VoIPManager {
    if (!VoIPManager.instance) {
      VoIPManager.instance = new VoIPManager();
    }
    return VoIPManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('VoIPManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async getTurnServer(): Promise<VoipTurnServerResponse> {
    try {
      return await this.ensureHttpClient().getVoipTurnServer();
    } catch (error) {
      console.error('Failed to get TURN server:', error);
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