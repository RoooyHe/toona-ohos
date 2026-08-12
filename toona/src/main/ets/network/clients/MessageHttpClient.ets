import { SendMessageResult, RelationsResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class MessageHttpClient extends BaseHttpClient {
  async sendEvent(
    roomId: string,
    eventType: string,
    txnId: string,
    content: Record<string, string | object>
  ): Promise<string> {
    const encodedRoomId = this.encodePath(roomId);
    const response = await this.put<SendMessageResult>(
      `/rooms/${encodedRoomId}/send/${eventType}/${txnId}`,
      content
    );
    return response.event_id;
  }

  async redactEvent(
    roomId: string,
    eventId: string,
    txnId: string,
    reason?: string
  ): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const body: Record<string, string | object> = {
      "reason": reason !== undefined ? reason : ''
    };
    await this.put<object>(`/rooms/${encodedRoomId}/redact/${encodedEventId}/${txnId}`, body);
  }

  async getRelations(
    roomId: string,
    eventId: string,
    relType?: string,
    eventType?: string,
    limit?: number,
    direction?: 'f' | 'b'
  ): Promise<RelationsResponse> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const queryParams = this.buildQueryParams({
      'rel_type': relType,
      'event_type': eventType,
      'limit': limit,
      'direction': direction
    });
    let endpoint = `/rooms/${encodedRoomId}/relations/${encodedEventId}`;
    if (relType !== undefined && eventType !== undefined) {
      endpoint += `/${relType}/${eventType}`;
    }
    return await this.get<RelationsResponse>(endpoint, queryParams);
  }

  async addAnnotation(
    roomId: string,
    eventId: string,
    relType: string,
    key: string,
    type: string,
    content: Record<string, string | object>
  ): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const body: Record<string, string | object> = { 'key': key };
    const contentKeys = Object.keys(content);
    for (let i = 0; i < contentKeys.length; i++) {
      const k = contentKeys[i];
      body[k] = content[k];
    }
    await this.put<void>(
      `/rooms/${encodedRoomId}/relations/${encodedEventId}/${relType}/${type}`,
      body
    );
  }
}
