import { AppLogger } from '../utils/AppLogger';
import { OpenIdRequest, OpenIdResponse } from '../models/MatrixTypes';
import { OpenIdHttpClient } from '../network/clients/OpenIdHttpClient';

export class OpenIdManager {
  private openIdClient: OpenIdHttpClient;
  private logger = AppLogger.getLogger(OpenIdManager);

  constructor(openIdClient: OpenIdHttpClient) {
    this.openIdClient = openIdClient;
  }

  async requestToken(userId: string, request?: OpenIdRequest): Promise<OpenIdResponse> {
    try {
      return await this.openIdClient.requestOpenIdToken(userId, request);
    } catch (error) {
      this.logger.error('Failed to request OpenID token:', error);
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
