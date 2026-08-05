import { Event, PresEvent } from '../models/MatrixTypes';
import { User, Room, Message } from '../models/DataModels';
import { LocalDatabase } from '../database/LocalDatabase';
import { AppLogger } from '../utils/AppLogger';
import { CryptoService, EncryptedMatrixEvent } from './CryptoService';
import { OlmWrapper } from '../crypto/OlmWrapper';

export interface IEventProcessor {
  processPresenceEvents(events: PresEvent[]): Promise<void>;

  processAccountDataEvents(events: Event[]): Promise<void>;

  processToDeviceEvents(events: Event[]): Promise<void>;

  processRoomEvent(event: Event): Event | ProcessedMessageEvent | ProcessedMemberEvent | ProcessedRoomEvent | ProcessedRedactionEvent | ProcessedEncryptedEvent | ProcessedStickerEvent;

  processEncryptedEventAsync(event: Event): Promise<ProcessedMessageEvent | null>;

  getMembershipEventContent(event: Event): Record<string, string | object>;

  getMessageBody(event: Event): string;

  getMessageType(event: Event): string;

  isTextMessage(event: Event): boolean;

  isEmoteMessage(event: Event): boolean;

  isNoticeMessage(event: Event): boolean;

  isImageMessage(event: Event): boolean;

  isAudioMessage(event: Event): boolean;

  isVideoMessage(event: Event): boolean;

  isFileMessage(event: Event): boolean;

  isLocationMessage(event: Event): boolean;
}

interface ProcessedMessageEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  content: Record<string, string | object>;
  timestamp: number | undefined;
  txnId: string | undefined;
}

interface ProcessedMemberContent {
  membership: string | undefined;
  displayname: string | undefined;
  avatar_url: string | undefined;
  reason: string | undefined;
}

interface ProcessedMemberEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  stateKey: string | undefined;
  content: ProcessedMemberContent;
  prevContent: ProcessedMemberContent | null;
  timestamp: number | undefined;
}

interface ProcessedRoomEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  content: Record<string, string | object>;
  timestamp: number | undefined;
}

interface ProcessedRedactionEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  content: Record<string, string | object>;
  redacts: string | undefined;
  timestamp: number | undefined;
}

interface ProcessedEncryptedEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  content: Record<string, string | object>;
  timestamp: number | undefined;
}

interface ProcessedStickerEvent {
  eventId: string | undefined;
  roomId: string | undefined;
  sender: string | undefined;
  type: string;
  content: Record<string, string | object>;
  timestamp: number | undefined;
}

export class EventProcessor implements IEventProcessor {
  private localDatabase: LocalDatabase;
  private logger = AppLogger.getLogger(EventProcessor);
  private cryptoService: CryptoService;

  constructor(localDatabase: LocalDatabase, cryptoService: CryptoService) {
    this.localDatabase = localDatabase;
    this.cryptoService = cryptoService;
  }

  async processPresenceEvents(events: PresEvent[]): Promise<void> {
    for (const event of events) {
      await this.processPresenceEvent(event);
    }
  }

  private async processPresenceEvent(event: PresEvent): Promise<void> {
    if (!event.sender) {
      return;
    }

    const presenceContent = event.content as Record<string, string | object>;

    const user = User.fromPresenceEvent(
      event.sender,
      presenceContent['presence'] as string | undefined,
      presenceContent['status_msg'] as string | undefined,
      typeof presenceContent['last_active_ago'] === 'number' ? presenceContent['last_active_ago'] as number : undefined,
      typeof presenceContent['currently_active'] === 'boolean' ? presenceContent['currently_active'] as boolean :
        undefined,
      presenceContent['avatar_url'] as string | undefined,
      presenceContent['displayname'] as string | undefined
    );
    await this.localDatabase.saveUser(user);
  }

  async processAccountDataEvents(events: Event[]): Promise<void> {
    for (const event of events) {
      this.logger.info(`Account data event: ${event.type} ${event.room_id}`);
    }
  }

  async processToDeviceEvents(events: Event[]): Promise<void> {
    for (const event of events) {
      this.logger.info(`To-device event: ${event.type}`);

      // Route crypto-related events to CryptoService
      if (this.cryptoService.isInitialized()) {
        const cryptoEventTypes = [
          'm.room_key',
          'm.room_key_request',
          'm.forwarded_room_key',
          'm.olm.allow',
          'm.olm.key_request'
        ];

        if (cryptoEventTypes.includes(event.type)) {
          try {
            await this.cryptoService.processToDeviceEvent({
              type: event.type,
              sender: event.sender || '',
              content: event.content as Record<string, string | object>
            });
          } catch (error) {
            this.logger.error(`Failed to process to-device event ${event.type}:`, error);
          }
        }
      }
    }
  }

  processRoomEvent(event: Event): Event | ProcessedMessageEvent | ProcessedMemberEvent | ProcessedRoomEvent | ProcessedRedactionEvent | ProcessedEncryptedEvent | ProcessedStickerEvent {
    switch (event.type) {
      case 'm.room.message':
        return this.processMessageEvent(event);
      case 'm.room.member':
        return this.processMemberEvent(event);
      case 'm.room.name':
        return this.processRoomNameEvent(event);
      case 'm.room.topic':
        return this.processTopicEvent(event);
      case 'm.room.avatar':
        return this.processAvatarEvent(event);
      case 'm.room.redaction':
        return this.processRedactionEvent(event);
      case 'm.room.encrypted':
        return this.processEncryptedEvent(event);
      case 'm.sticker':
        return this.processStickerEvent(event);
      default:
        return event;
    }
  }

  private processMessageEvent(event: Event): ProcessedMessageEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: event.content,
      timestamp: event.origin_server_ts,
      txnId: event.unsigned?.transaction_id
    };
  }

  private processMemberEvent(event: Event): ProcessedMemberEvent {
    const content = event.content as Record<string, string | object>;
    const prevContent = event.unsigned?.prev_content as Record<string, string | object> | undefined;

    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      stateKey: event.state_key,
      content: {
        membership: content['membership'] as string | undefined,
        displayname: content['displayname'] as string | undefined,
        avatar_url: content['avatar_url'] as string | undefined,
        reason: content['reason'] as string | undefined
      },
      prevContent: prevContent ? {
        membership: prevContent['membership'] as string | undefined,
        displayname: prevContent['displayname'] as string | undefined,
        avatar_url: prevContent['avatar_url'] as string | undefined,
        reason: undefined
      } : null,
      timestamp: event.origin_server_ts
    };
  }

  private processRoomNameEvent(event: Event): ProcessedRoomEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        "name": event.content['name']
      },
      timestamp: event.origin_server_ts
    };
  }

  private processTopicEvent(event: Event): ProcessedRoomEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        "topic": event.content['topic']
      },
      timestamp: event.origin_server_ts
    };
  }

  private processAvatarEvent(event: Event): ProcessedRoomEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        "url": event.content['url']
      },
      timestamp: event.origin_server_ts
    };
  }

  private processRedactionEvent(event: Event): ProcessedRedactionEvent {
    const reasonValue = event.content['reason'];
    const contentRecord: Record<string, string | object> = {
      "reason": reasonValue !== undefined ? reasonValue : ''
    };
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: contentRecord,
      redacts: event.redacts,
      timestamp: event.origin_server_ts
    };
  }

  /**
   * Process an encrypted event
   * Returns either the decrypted message event or the encrypted event as-is
   */
  private processEncryptedEvent(event: Event): ProcessedEncryptedEvent | ProcessedMessageEvent {
    // If crypto is not initialized, return encrypted event as-is
    if (!this.cryptoService.isInitialized()) {
      return this.createEncryptedEventResult(event);
    }

    // Attempt to decrypt the event synchronously using the session cache
    try {
      const decryptedResult = this.attemptDecryptionFromCache(event, this.cryptoService);
      if (decryptedResult) {
        return decryptedResult;
      }
    } catch (error) {
      this.logger.error(`Failed to decrypt event ${event.event_id}:`, error);
    }

    // If decryption fails, return encrypted event as-is
    return this.createEncryptedEventResult(event);
  }

  /**
   * Create the result for an encrypted event that couldn't be decrypted
   */
  private createEncryptedEventResult(event: Event): ProcessedEncryptedEvent {
    const contentRecord: Record<string, string | object> = {
      "algorithm": event.content['algorithm'],
      "ciphertext": event.content['ciphertext'],
      "deviceId": event.content['device_id'],
      "sessionId": event.content['session_id']
    };
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: contentRecord,
      timestamp: event.origin_server_ts
    };
  }

  /**
   * Attempt to decrypt an event using cached sessions
   * This is a synchronous operation for performance
   */
  private attemptDecryptionFromCache(event: Event, cryptoService: CryptoService): ProcessedMessageEvent | null {
    const content: Record<string, string | object> = event.content as Record<string, string | object>;
    const sessionId: string = content['session_id'] as string;
    const ciphertext: string = content['ciphertext'] as string;

    if (!sessionId || !ciphertext) {
      return null;
    }

    return null;
  }

  /**
   * Process an encrypted event asynchronously
   * This is called after the sync loop completes
   */
  async processEncryptedEventAsync(event: Event): Promise<ProcessedMessageEvent | null> {
    if (!this.cryptoService.isInitialized()) {
      return null;
    }

    try {
      const decryptEventObj: EncryptedMatrixEvent = {
        event_id: event.event_id || '',
        room_id: event.room_id || '',
        sender: event.sender || '',
        type: event.type,
        content: event.content as Record<string, string | object>,
        origin_server_ts: event.origin_server_ts || 0
      };
      const decrypted = await this.cryptoService.decryptEvent(decryptEventObj);

      // If decryption was successful (no error), return as a message event
      if (!decrypted.decryptionError) {
        return {
          eventId: decrypted.eventId,
          roomId: decrypted.roomId,
          sender: decrypted.sender,
          type: decrypted.type,
          content: decrypted.content,
          timestamp: decrypted.timestamp,
          txnId: event.unsigned?.transaction_id
        };
      }
    } catch (error) {
      this.logger.error(`Async decryption failed for event ${event.event_id}:`, error);
    }

    return null;
  }

  private processStickerEvent(event: Event): ProcessedStickerEvent {
    const contentRecord: Record<string, string | object> = {
      "body": event.content['body'],
      "info": event.content['info'],
      "url": event.content['url']
    };
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: contentRecord,
      timestamp: event.origin_server_ts
    };
  }

  getMembershipEventContent(event: Event): Record<string, string | object> {
    return event.content;
  }

  getMessageBody(event: Event): string {
    const body = event.content['body'];
    if (body !== undefined) {
      return String(body);
    }
    return '';
  }

  getMessageType(event: Event): string {
    const msgtype = event.content['msgtype'];
    if (msgtype !== undefined) {
      return String(msgtype);
    }
    return 'm.text';
  }

  isTextMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.text';
  }

  isEmoteMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.emote';
  }

  isNoticeMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.notice';
  }

  isImageMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.image';
  }

  isAudioMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.audio';
  }

  isVideoMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.video';
  }

  isFileMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.file';
  }

  isLocationMessage(event: Event): boolean {
    return this.getMessageType(event) === 'm.location';
  }
}
