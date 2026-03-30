import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { OpenIdRequest, OpenIdResponse } from '../models/MatrixTypes';

export class OpenIdManager {
  private static instance: OpenIdManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): OpenIdManager {
    if (!OpenIdManager.instance) {
      OpenIdManager.instance = new OpenIdManager();
    }
    return OpenIdManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('OpenIdManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async requestToken(userId: string, request?: OpenIdRequest): Promise<OpenIdResponse> {
    try {
      return await this.ensureHttpClient().requestOpenIdToken(userId, request);
    } catch (error) {
      console.error('Failed to request OpenID token:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to request OpenID token: ${errMsg}`);
    }
  }

  private createOpenIdRequest(nonce?: string): OpenIdRequest | undefined {
    if (nonce === undefined) {
      return undefined;
    }
    const req: OpenIdRequest = { nonce: nonce };
    return req;
  }

  async exchangeToken(userId: string, nonce?: string): Promise<OpenIdResponse> {
    const request: OpenIdRequest | undefined = this.createOpenIdRequest(nonce);
    return this.requestToken(userId, request);
  }
}