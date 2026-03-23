import { Event, PresEvent } from '../models/MatrixTypes';
import { User, Room } from '../models/DataModels';
import { LocalDatabase } from '../database/LocalDatabase';

export interface SyncListener {
  onSyncSuccess(): void;
  onSyncError(error: Error): void;
  onRoomUpdated(room: Room): void;
  onRoomInvited(room: Room): void;
  onRoomLeft(roomId: string): void;
  onNewMessages(roomId: string, messages: Room[]): void;
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

type SyncSuccessCallback = () => void;
type SyncErrorCallback = (error: Error) => void;
type RoomUpdatedCallback = (room: Room) => void;
type RoomInvitedCallback = (room: Room) => void;
type RoomLeftCallback = (roomId: string) => void;
type NewMessagesCallback = (roomId: string, messages: Room[]) => void;

export class SimpleSyncListener implements SyncListener {
  private onSyncSuccessCb?: SyncSuccessCallback;
  private onSyncErrorCb?: SyncErrorCallback;
  private onRoomUpdatedCb?: RoomUpdatedCallback;
  private onRoomInvitedCb?: RoomInvitedCallback;
  private onRoomLeftCb?: RoomLeftCallback;
  private onNewMessagesCb?: NewMessagesCallback;

  constructor(config: {
    onSyncSuccess?: SyncSuccessCallback;
    onSyncError?: SyncErrorCallback;
    onRoomUpdated?: RoomUpdatedCallback;
    onRoomInvited?: RoomInvitedCallback;
    onRoomLeft?: RoomLeftCallback;
    onNewMessages?: NewMessagesCallback;
  }) {
    this.onSyncSuccessCb = config.onSyncSuccess;
    this.onSyncErrorCb = config.onSyncError;
    this.onRoomUpdatedCb = config.onRoomUpdated;
    this.onRoomInvitedCb = config.onRoomInvited;
    this.onRoomLeftCb = config.onRoomLeft;
    this.onNewMessagesCb = config.onNewMessages;
  }

  onSyncSuccess(): void {
    if (this.onSyncSuccessCb) {
      this.onSyncSuccessCb();
    }
  }

  onSyncError(error: Error): void {
    if (this.onSyncErrorCb) {
      this.onSyncErrorCb(error);
    }
  }

  onRoomUpdated(room: Room): void {
    if (this.onRoomUpdatedCb) {
      this.onRoomUpdatedCb(room);
    }
  }

  onRoomInvited(room: Room): void {
    if (this.onRoomInvitedCb) {
      this.onRoomInvitedCb(room);
    }
  }

  onRoomLeft(roomId: string): void {
    if (this.onRoomLeftCb) {
      this.onRoomLeftCb(roomId);
    }
  }

  onNewMessages(roomId: string, messages: Room[]): void {
    if (this.onNewMessagesCb) {
      this.onNewMessagesCb(roomId, messages);
    }
  }
}

export class EventProcessor {
  private static instance: EventProcessor;
  private localDatabase: LocalDatabase;

  private constructor() {
    this.localDatabase = LocalDatabase.getInstance();
  }

  static getInstance(): EventProcessor {
    if (!EventProcessor.instance) {
      EventProcessor.instance = new EventProcessor();
    }
    return EventProcessor.instance;
  }

  async processPresenceEvents(events: Event[]): Promise<void> {
    for (const event of events) {
      if (event.type === 'm.presence') {
        await this.processPresenceEvent(event);
      }
    }
  }

  private async processPresenceEvent(event: Event): Promise<void> {
    if (!event.sender) return;

    const user = User.fromPresenceEvent(event);
    await this.localDatabase.saveUser(user);
  }

  async processAccountDataEvents(events: Event[]): Promise<void> {
    for (const event of events) {
      console.info('Account data event:', event.type, event.room_id);
    }
  }

  async processToDeviceEvents(events: Event[]): Promise<void> {
    for (const event of events) {
      console.info('To-device event:', event.type);
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
        name: event.content['name']
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
        topic: event.content['topic']
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
        url: event.content['url']
      },
      timestamp: event.origin_server_ts
    };
  }

  private processRedactionEvent(event: Event): ProcessedRedactionEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        reason: event.content['reason']
      },
      redacts: event.redacts,
      timestamp: event.origin_server_ts
    };
  }

  private processEncryptedEvent(event: Event): ProcessedEncryptedEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        algorithm: event.content['algorithm'],
        ciphertext: event.content['ciphertext'],
        deviceId: event.content['device_id'],
        sessionId: event.content['session_id']
      },
      timestamp: event.origin_server_ts
    };
  }

  private processStickerEvent(event: Event): ProcessedStickerEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        body: event.content['body'],
        info: event.content['info'],
        url: event.content['url']
      },
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
