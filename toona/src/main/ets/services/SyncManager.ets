import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { SyncRequest, SyncResponse, Event, RoomState } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Room, Message, TagInfo } from '../models/DataModels';
import { EventProcessor, SyncListener } from './EventProcessor';
import { Context } from '@kit.AbilityKit';
import { AppLogger } from '../utils/AppLogger';

const DEFAULT_TIMEOUT = 30000;
const INITIAL_SYNC_TIMEOUT = 10000;

export class SyncManager {
  private static instance: SyncManager;
  private logger = AppLogger.getLogger(SyncManager);
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
  private syncSuccessCallbacks: Array<() => void> = [];
  private syncErrorCallbacks: Array<(error: Error) => void> = [];
  private roomUpdatedCallbacks: Array<(room: Room) => void> = [];
  private roomInvitedCallbacks: Array<(room: Room) => void> = [];
  private roomLeftCallbacks: Array<(roomId: string) => void> = [];
  private newMessagesCallbacks: Array<(roomId: string, messages: Message[]) => void> = [];

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
    if (!this.syncSuccessCallbacks.includes(callback)) {
      this.syncSuccessCallbacks.push(callback);
    }
  }

  setSyncErrorCallback(callback: (error: Error) => void): void {
    if (!this.syncErrorCallbacks.includes(callback)) {
      this.syncErrorCallbacks.push(callback);
    }
  }

  setRoomUpdatedCallback(callback: (room: Room) => void): void {
    if (!this.roomUpdatedCallbacks.includes(callback)) {
      this.roomUpdatedCallbacks.push(callback);
    }
  }

  setRoomInvitedCallback(callback: (room: Room) => void): void {
    if (!this.roomInvitedCallbacks.includes(callback)) {
      this.roomInvitedCallbacks.push(callback);
    }
  }

  setRoomLeftCallback(callback: (roomId: string) => void): void {
    if (!this.roomLeftCallbacks.includes(callback)) {
      this.roomLeftCallbacks.push(callback);
    }
  }

  setNewMessagesCallback(callback: (roomId: string, messages: Message[]) => void): void {
    if (!this.newMessagesCallbacks.includes(callback)) {
      this.newMessagesCallbacks.push(callback);
    }
  }

  clearAllCallbacks(): void {
    this.syncSuccessCallbacks = [];
    this.syncErrorCallbacks = [];
    this.roomUpdatedCallbacks = [];
    this.roomInvitedCallbacks = [];
    this.roomLeftCallbacks = [];
    this.newMessagesCallbacks = [];
  }

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
        this.logger.error('Sync error:', error);
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
        const currentUserId = this.authManager.getSession()?.userId || '';
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
            } else if (event.type === 'm.room.create') {
              const isDirectVal = content['is_direct'];
              if (isDirectVal !== undefined) {
                room.isDirect = isDirectVal === 'true';
              }
              const typeVal = content['type'];
              if (typeVal === 'm.space') {
                room.isSpace = true;
              }
            } else if (event.type === 'm.room.member') {
              const stateKey = event.state_key;
              if (stateKey && stateKey !== currentUserId) {
                const displaynameVal = content['displayname'];
                if (displaynameVal !== undefined) {
                  room.displayName = String(displaynameVal);
                }
                const avatarVal = content['avatar_url'];
                if (avatarVal !== undefined) {
                  room.avatarUrl = String(avatarVal);
                }
              }
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
    const currentUserId = this.authManager.getSession()?.userId || '';
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
      } else if (event.type === 'm.room.create') {
        const isDirectVal = content['is_direct'];
        if (isDirectVal !== undefined) {
          room.isDirect = isDirectVal === 'true';
        }
        const typeVal = content['type'];
        if (typeVal === 'm.space') {
          room.isSpace = true;
        }
      } else if (event.type === 'm.room.member') {
        const stateKey = event.state_key;
        if (stateKey && stateKey !== currentUserId) {
          const displaynameVal = content['displayname'];
          if (displaynameVal !== undefined) {
            room.displayName = String(displaynameVal);
          }
          const avatarVal = content['avatar_url'];
          if (avatarVal !== undefined) {
            room.avatarUrl = String(avatarVal);
          }
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

    if (roomState.account_data?.events) {
      for (const event of roomState.account_data.events) {
        if (event.type === 'm.tag') {
          const content = event.content as Record<string, object>;
          const tagsContent = content['tags'];
          if (tagsContent && typeof tagsContent === 'object') {
            const tags: Record<string, TagInfo> = {};
            const tagObj = tagsContent as Record<string, object>;
            const tagKeys = Object.keys(tagObj);
            for (let i = 0; i < tagKeys.length; i++) {
              const tagName = tagKeys[i];
              const tagData = tagObj[tagName];
              if (tagData && typeof tagData === 'object') {
                const tagDataObj = tagData as Record<string, object>;
                const orderVal = tagDataObj['order'];
                tags[tagName] = {
                  order: typeof orderVal === 'number' ? orderVal : undefined
                };
              }
            }
            room.tags = tags;
            this.logger.info(`SyncManager: Room ${roomId} has tags: ${Object.keys(tags).join(', ')}`);
          }
        }
      }
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
    this.logger.info(`SyncManager: notifySyncSuccess called, callbacks count:', ${this.syncSuccessCallbacks.length}`);
    for (const callback of this.syncSuccessCallbacks) {
      try {
        this.logger.info('SyncManager: calling syncSuccessCallback');
        callback();
        this.logger.info('SyncManager: syncSuccessCallback completed');
      } catch (error) {
        this.logger.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onSyncSuccess();
      } catch (error) {
        this.logger.error('Sync listener error:', error);
      }
    }
  }

  private notifySyncError(error: Error): void {
    this.logger.info(`SyncManager: notifySyncError called, callbacks count: ${this.syncErrorCallbacks.length} `);
    for (const callback of this.syncErrorCallbacks) {
      try {
        callback(error);
      } catch (err) {
        this.logger.error('Sync callback error:', err);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onSyncError(error);
      } catch (err) {
        this.logger.error('Sync listener error:', err);
      }
    }
  }

  private notifyRoomUpdated(room: Room): void {
    for (const callback of this.roomUpdatedCallbacks) {
      try {
        callback(room);
      } catch (error) {
        this.logger.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomUpdated(room);
      } catch (error) {
        this.logger.error('Sync listener error:', error);
      }
    }
  }

  private notifyRoomInvited(room: Room): void {
    for (const callback of this.roomInvitedCallbacks) {
      try {
        callback(room);
      } catch (error) {
        this.logger.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomInvited(room);
      } catch (error) {
        this.logger.error('Sync listener error:', error);
      }
    }
  }

  private notifyRoomLeft(roomId: string): void {
    for (const callback of this.roomLeftCallbacks) {
      try {
        callback(roomId);
      } catch (error) {
        this.logger.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onRoomLeft(roomId);
      } catch (error) {
        this.logger.error('Sync listener error:', error);
      }
    }
  }

  private notifyNewMessages(roomId: string, messages: Message[]): void {
    for (const callback of this.newMessagesCallbacks) {
      try {
        callback(roomId, messages);
      } catch (error) {
        this.logger.error('Sync callback error:', error);
      }
    }
    for (const listener of this.listeners) {
      try {
        listener.onNewMessages(roomId, messages);
      } catch (error) {
        this.logger.error('Sync listener error:', error);
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
