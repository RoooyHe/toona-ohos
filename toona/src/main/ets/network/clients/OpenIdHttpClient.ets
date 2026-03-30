import { OpenIdRequest, OpenIdResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class OpenIdHttpClient extends BaseHttpClient {
  async requestOpenIdToken(userId: string, request: OpenIdRequest | undefined): Promise<OpenIdResponse> {
    const encodedUserId = encodeURIComponent(userId);
    const body: Record<string, string | object> = {};
    if (request !== undefined) {
      const keys = Object.keys(request);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = (request as Record<string, string | number | undefined>)[key];
        if (value !== undefined) {
          body[key] = value as string | object;
        }
      }
    }
    return await this.post<OpenIdResponse>(`/user/${encodedUserId}/openid`, body);
  }
}
