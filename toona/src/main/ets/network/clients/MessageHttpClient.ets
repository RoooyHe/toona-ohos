import { RelationsResponse, ReceiptContent } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

interface GeneratedTypeLiteralInterface_1 {
  user_ids: string[];
}

export class MessageHttpClient extends BaseHttpClient {
  async putTyping(roomId: string, userId: string, typing: boolean, timeout?: number): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedUserId = encodeURIComponent(userId);
    const body: Record<string, string | object> = { "typing": typing ? 'true' : 'false' };
    if (timeout !== undefined) {
      body['timeout'] = String(timeout);
    }
    await this.put<void>(
      `/rooms/${encodedRoomId}/typing/${encodedUserId}`,
      body
    );
  }

  async getTypingUsers(roomId: string, userId: string): Promise<string[]> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedUserId = encodeURIComponent(userId);
    const response = await this.get<GeneratedTypeLiteralInterface_1>(
      `/rooms/${encodedRoomId}/typing/${encodedUserId}`
    );
    return response.user_ids || [];
  }

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

  async getReceipt(roomId: string, receiptType: string, eventId: string): Promise<ReceiptContent> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedEventId = encodeURIComponent(eventId);
    return await this.get<ReceiptContent>(
      `/rooms/${encodedRoomId}/receipt/${receiptType}/${encodedEventId}`
    );
  }

  async postReceipt(roomId: string, receiptType: string, eventId: string, threadId?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedEventId = encodeURIComponent(eventId);
    const body: Record<string, string | object> = {};
    if (threadId !== undefined) {
      body['thread_id'] = threadId;
    }
    await this.post<void>(
      `/rooms/${encodedRoomId}/receipt/${receiptType}/${encodedEventId}`,
      body
    );
  }
}
