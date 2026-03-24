import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { SyncRequest, SyncResponse, Event, RoomState } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Room, Message } from '../models/DataModels';
import { EventProcessor, SyncListener } from './EventProcessor';
import { Context } from '@kit.AbilityKit';

const DEFAULT_TIMEOUT = 30000;
const INITIAL_SYNC_TIMEOUT = 10000;

export class SyncManager {
  private static instance: SyncManager;
  private httpClient: MatrixHttpClient;
  private authManager: AuthManager;
  private localDatabase: LocalDatabase;
  private eventProcessor: EventProcessor;
  private isRunning: boolean = false;
  private isInitialSync: boolean = true;
  private syncTimeout: number = DEFAULT_TIMEOUT;
  private nextBatch: string = '';
  private listeners: SyncListener[] = [];
  private syncTask: Promise<void> | null = null;

  private constructor() {
    this.authManager = AuthManager.getInstance();
    this.httpClient = this.authManager.getHttpClient();
    this.localDatabase = LocalDatabase.getInstance();
    this.eventProcessor = EventProcessor.getInstance();
  }

  static getInstance(): SyncManager {
    if (!SyncManager.instance) {
      SyncManager.instance = new SyncManager();
    }
    return SyncManager.instance;
  }

  async init(context: Context): Promise<void> {
    await this.localDatabase.init(context);
  }

  addListener(listener: SyncListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  removeListener(listener: SyncListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  setSyncSuccessCallback(callback: () => void): void {
    this.syncSuccessCallback = callback;
  }

  setSyncErrorCallback(callback: (error: Error) => void): void {
    this.syncErrorCallback = callback;
  }

  setRoomUpdatedCallback(callback: (room: Room) => void): void {
    this.roomUpdatedCallback = callback;
  }

  setRoomInvitedCallback(callback: (room: Room) => void): void {
    this.roomInvitedCallback = callback;
  }

  setRoomLeftCallback(callback: (roomId: string) => void): void {
    this.roomLeftCallback = callback;
  }

  setNewMessagesCallback(callback: (roomId: string, messages: Message[]) => void): void {
    this.newMessagesCallback = callback;
  }

  clearAllCallbacks(): void {
    this.syncSuccessCallback = undefined;
    this.syncErrorCallback = undefined;
    this.roomUpdatedCallback = undefined;
    this.roomInvitedCallback = undefined;
    this.roomLeftCallback = undefined;
    this.newMessagesCallback = undefined;
  }

  private syncSuccessCallback?: () => void;
  private syncErrorCallback?: (error: Error) => void;
  private roomUpdatedCallback?: (room: Room) => void;
  private roomInvitedCallback?: (room: Room) => void;
  private roomLeftCallback?: (roomId: string) => void;
  private newMessagesCallback?: (roomId: string, messages: Message[]) => void;

  async start(): Promise<void> {
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;
    this.syncTask = this.syncLoop();
  }

  async stop(): Promise<void> {
    this.isRunning = false;
    if (this.syncTask) {
      await this.syncTask;
      this.syncTask = null;
    }
  }

  private async syncLoop(): Promise<void> {
    while (this.isRunning) {
      try {
        await this.performSync();
      } catch (error) {
        console.error('Sync error:', error);
        this.notifySyncError(error);
        await this.delay(5000);
      }
    }
  }

  private async performSync(): Promise<void> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No session');
    }

    const request: SyncRequest = {
      timeout: this.isInitialSync ? INITIAL_SYNC_TIMEOUT : this.syncTimeout
    };

    if (this.nextBatch) {
      request.since = this.nextBatch;
    } else if (session.nextBatch) {
      request.since = session.nextBatch;
    }

    request.full_state = this.isInitialSync;

    const response = await this.httpClient.get<SyncResponse>('/sync', request as Record<string, string>);

    this.nextBatch = response.next_batch;
    await this.authManager.updateNextBatch(response.next_batch);

    await this.processSyncResponse(response);

    if (this.isInitialSync) {
      this.isInitialSync = false;
    }

    this.notifySyncSuccess();
  }

  private async processSyncResponse(response: SyncResponse): Promise<void> {
    if (response.rooms) {
      if (response.rooms.join) {
        const joinEntries = Object.entries(response.rooms.join);
        for (let i = 0; i < joinEntries.length; i++) {
          const entry = joinEntries[i];
          await this.processJoinedRoom(entry[0], entry[1]);
        }
      }

      if (response.rooms.invite) {
        const inviteEntries = Object.entries(response.rooms.invite);
        for (let i = 0; i < inviteEntries.length; i++) {
          const entry = inviteEntries[i];
          const roomId = entry[0];
          const invitedRoom = entry[1];
          const room = new Room(roomId);
          room.myMembership = 'invite';
          const inviteState = invitedRoom.invite_state?.events || [];
          for (let j = 0; j < inviteState.length; j++) {
            const event = inviteState[j];
            const content = event.content as Record<string, string | object>;
            if (event.type === 'm.room.name') {
              room.name = String(content['name'] || '');
              room.displayName = String(content['name'] || '');
            } else if (event.type === 'm.room.canonical_alias') {
              room.name = String(content['alias'] || '');
            } else if (event.type === 'm.room.avatar') {
              room.avatarUrl = String(content['url'] || '');
            }
          }
          await this.localDatabase.saveRoom(room);
          this.notifyRoomInvited(room);
        }
      }

      if (response.rooms.leave) {
        const leaveEntries = Object.entries(response.rooms.leave);
        for (let i = 0; i < leaveEntries.length; i++) {
          const entry = leaveEntries[i];
          const leftRoomId = entry[0];
          await this.localDatabase.deleteRoom(leftRoomId);
          this.notifyRoomLeft(leftRoomId);
        }
      }
    }

    if (response.presence?.events) {
      await this.eventProcessor.processPresenceEvents(response.presence.events);
    }

    if (response.account_data?.events) {
      await this.eventProcessor.processAccountDataEvents(response.account_data.events);
    }

    if (response.to_device?.events) {
      await this.eventProcessor.processToDeviceEvents(response.to_device.events);
    }
  }

  private async processJoinedRoom(roomId: string, roomState: RoomState): Promise<void> {
    const room = new Room(roomId);
    room.myMembership = 'join';

    if (roomState.summary) {
      if (roomState.summary.joined_member_count !== undefined) {
        room.memberCount = roomState.summary.joined_member_count;
      }
      if (roomState.summary.invited_member_count !== undefined) {
        room.memberCount = roomState.summary.invited_member_count;
      }
    }

    const stateEvents = roomState.state?.events || [];
    for (let i = 0; i < stateEvents.length; i++) {
      const event = stateEvents[i];
      const content = event.content as Record<string, string | object>;
      if (event.type === 'm.room.name') {
        const nameVal = content['name'];
        if (nameVal !== undefined) {
          room.name = String(nameVal);
          room.displayName = String(nameVal);
        }
      } else if (event.type === 'm.room.topic') {
        const topicVal = content['topic'];
        if (topicVal !== undefined) {
          room.topic = String(topicVal);
        }
      } else if (event.type === 'm.room.avatar') {
        const avatarVal = content['url'];
        if (avatarVal !== undefined) {
          room.avatarUrl = String(avatarVal);
        }
      } else if (event.type === 'm.room.canonical_alias') {
        const aliasVal = content['alias'];
        if (aliasVal !== undefined) {
          room.name = String(aliasVal);
        }
      }
    }

    if (roomState.timeline?.events && roomState.timeline.events.length > 0) {
      const lastEvent = roomState.timeline.events[roomState.timeline.events.length - 1];
      room.lastEvent = lastEvent;
      room.lastEventTime = lastEvent?.origin_server_ts;
    }

    if (roomState.unread_notifications) {
      room.unreadCount = roomState.unread_notifications.notification_count;
      room.highlightCount = roomState.unread_notifications.highlight_count;
    }

    await this.localDatabase.saveRoom(room);

    if (roomState.timeline?.events) {
      const currentUserId = this.authManager.getSession()?.userId || '';
      const messages: Message[] = [];

      for (let i = 0; i < roomState.timeline.events.length; i++) {
        const event = roomState.timeline.events[i];
        if (this.isMessageEvent(event)) {
          const message = Message.fromEvent(event, currentUserId);
          messages.push(message);
        }
      }

      if (messages.length > 0) {
        await this.localDatabase.saveMessages(messages);
        this.notifyNewMessages(roomId, messages);
      }
    }

    this.notifyRoomUpdated(room);
  }

  private isMessageEvent(event: Event): boolean {
    return event.type === 'm.room.message' ||
      event.type === 'm.room.encrypted' ||
      event.type === 'm.sticker' ||
      event.type === 'm.room.redaction';
  }

  private notifySyncSuccess(): void {
    if (this.syncSuccessCallback) {
      try {
        this.syncSuccessCallback();
      } catch (error) {
        console.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onSyncSuccess();
      } catch (error) {
        console.error('Sync listener error:', error);
      }
    }
  }

  private notifySyncError(error: Error): void {
    if (this.syncErrorCallback) {
      try {
        this.syncErrorCallback(error);
      } catch (err) {
        console.error('Sync callback error:', err);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onSyncError(error);
      } catch (err) {
        console.error('Sync listener error:', err);
      }
    }
  }

  private notifyRoomUpdated(room: Room): void {
    if (this.roomUpdatedCallback) {
      try {
        this.roomUpdatedCallback(room);
      } catch (error) {
        console.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomUpdated(room);
      } catch (error) {
        console.error('Sync listener error:', error);
      }
    }
  }

  private notifyRoomInvited(room: Room): void {
    if (this.roomInvitedCallback) {
      try {
        this.roomInvitedCallback(room);
      } catch (error) {
        console.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomInvited(room);
      } catch (error) {
        console.error('Sync listener error:', error);
      }
    }
  }

  private notifyRoomLeft(roomId: string): void {
    if (this.roomLeftCallback) {
      try {
        this.roomLeftCallback(roomId);
      } catch (error) {
        console.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomLeft(roomId);
      } catch (error) {
        console.error('Sync listener error:', error);
      }
    }
  }

  private notifyNewMessages(roomId: string, messages: Message[]): void {
    if (this.newMessagesCallback) {
      try {
        this.newMessagesCallback(roomId, messages);
      } catch (error) {
        console.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onNewMessages(roomId, messages);
      } catch (error) {
        console.error('Sync listener error:', error);
      }
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  reset(): void {
    this.isRunning = false;
    this.isInitialSync = true;
    this.nextBatch = '';
    this.listeners = [];
    this.syncTask = null;
  }
}
