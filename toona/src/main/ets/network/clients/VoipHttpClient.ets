import { VoipTurnServerResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class VoipHttpClient extends BaseHttpClient {
  async getVoipTurnServer(): Promise<VoipTurnServerResponse> {
    return await this.get<VoipTurnServerResponse>('/voip/turnServer');
  }
}
