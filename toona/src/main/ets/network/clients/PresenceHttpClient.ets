import {
  GetPresenceResponse,
  SetPresenceRequest,
  PresenceListRequest,
  PresenceListResponse
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class PresenceHttpClient extends BaseHttpClient {
  private toBody(obj: object): Record<string, string | object> {
    return JSON.parse(JSON.stringify(obj)) as Record<string, string | object>;
  }

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    const encodedUserId = encodeURIComponent(userId);
    return await this.get<GetPresenceResponse>(`/presence/${encodedUserId}/status`);
  }

  async setPresence(userId: string, request: SetPresenceRequest): Promise<void> {
    const encodedUserId = encodeURIComponent(userId);
    const body: Record<string, string | object> = { 'presence': request.presence };
    if (request.status_msg !== undefined) {
      body['status_msg'] = request.status_msg;
    }
    await this.put<void>(`/presence/${encodedUserId}/status`, body);
  }

  async getPresenceList(userIds: string[]): Promise<PresenceListResponse> {
    const request: PresenceListRequest = { nodes: userIds };
    return await this.post<PresenceListResponse>('/presence/list', this.toBody(request));
  }
}
