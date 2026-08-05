import { RelationsResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class MessageHttpClient extends BaseHttpClient {
  async getRelations(
    roomId: string,
    eventId: string,
    relType?: string,
    eventType?: string,
    limit?: number,
    direction?: 'f' | 'b'
  ): Promise<RelationsResponse> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedEventId = encodeURIComponent(eventId);
    const queryParams: Record<string, string | number> = {};
    if (relType !== undefined) {
      queryParams['rel_type'] = relType;
    }
    if (eventType !== undefined) {
      queryParams['event_type'] = eventType;
    }
    if (limit !== undefined) {
      queryParams['limit'] = limit;
    }
    if (direction !== undefined) {
      queryParams['direction'] = direction;
    }
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
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedEventId = encodeURIComponent(eventId);
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
