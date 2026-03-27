import {
  User as MatrixUser,
  Room as MatrixRoom,
  MessageStatus,
  Event,
  RoomSummary,
  UnreadNotifications
} from '../models/MatrixTypes';

interface StateEventList {
  events: Event[];
}

interface TimelineEvents {
  events: Event[];
  limited?: boolean;
  prev_batch?: string;
}

interface SyncRoomState {
  summary?: RoomSummary;
  state: StateEventList;
  timeline: TimelineEvents;
  unread_notifications?: UnreadNotifications;
}

interface ProfileData {
  displayname?: string;
  avatar_url?: string;
}

export class Session {
  userId: string = '';
  accessToken: string = '';
  homeServer: string = '';
  deviceId: string = '';
  isGuest: boolean = false;
  nextBatch: string = '';

  static fromLoginResponse(
    userId: string,
    accessToken: string,
    homeServer: string,
    deviceId: string
  ): Session {
    const session = new Session();
    session.userId = userId;
    session.accessToken = accessToken;
    session.homeServer = homeServer;
    session.deviceId = deviceId;
    return session;
  }

  toJSON(): Record<string, string> {
    return {
      'userId': this.userId,
      'accessToken': this.accessToken,
      'homeServer': this.homeServer,
      'deviceId': this.deviceId,
      'isGuest': this.isGuest.toString(),
      'nextBatch': this.nextBatch
    };
  }

  static fromJSON(json: Record<string, string>): Session {
    const session = new Session();
    session.userId = json.userId || '';
    session.accessToken = json.accessToken || '';
    session.homeServer = json.homeServer || '';
    session.deviceId = json.deviceId || '';
    session.isGuest = json.isGuest === 'true';
    session.nextBatch = json.nextBatch || '';
    return session;
  }
}

export class Room implements MatrixRoom {
  id: string;
  name?: string;
  displayName?: string;
  topic?: string;
  avatarUrl?: string;
  memberCount?: number;
  joinedMembers?: string[];
  myMembership?: string;
  isDirect?: boolean;
  isSpace?: boolean;
  unreadCount?: number;
  highlightCount?: number;
  lastEvent?: Event;
  lastEventTime?: number;

  constructor(roomId: string) {
    this.id = roomId;
  }

  static fromMatrixRoomState(roomId: string, state: SyncRoomState): Room {
    const room = new Room(roomId);
    room.myMembership = 'join';

    if (state.summary) {
      const summary: RoomSummary = state.summary;
      if (summary.joined_member_count !== undefined) {
        room.memberCount = summary.joined_member_count;
      }
      if (summary.invited_member_count !== undefined) {
        room.memberCount = summary.invited_member_count;
      }
    }

    const stateEvents: Event[] = state.state?.events || [];
    for (let i = 0; i < stateEvents.length; i++) {
      const event: Event = stateEvents[i];
      const content: Record<string, string | object> = event.content as Record<string, string | object>;
      switch (event.type) {
        case 'm.room.name':
          const nameVal: string | object | undefined = content['name'];
          if (nameVal !== undefined) {
            room.name = String(nameVal);
            room.displayName = String(nameVal);
          }
          break;
        case 'm.room.topic':
          const topicVal: string | object | undefined = content['topic'];
          if (topicVal !== undefined) {
            room.topic = String(topicVal);
          }
          break;
        case 'm.room.avatar':
          const avatarVal: string | object | undefined = content['url'];
          if (avatarVal !== undefined) {
            room.avatarUrl = String(avatarVal);
          }
          break;
        case 'm.room.canonical_alias':
          const aliasVal: string | object | undefined = content['alias'];
          if (aliasVal !== undefined) {
            room.name = String(aliasVal);
          }
          break;
        case 'm.room.create':
          const isDirectVal: string | object | undefined = content['is_direct'];
          if (isDirectVal !== undefined) {
            room.isDirect = isDirectVal === 'true';
          }
          const typeVal: string | object | undefined = content['type'];
          if (typeVal === 'm.space') {
            room.isSpace = true;
          }
          break;
      }
    }

    if (state.timeline?.events && state.timeline.events.length > 0) {
      const timelineEvents: Event[] = state.timeline.events;
      room.lastEvent = timelineEvents[timelineEvents.length - 1];
      if (room.lastEvent) {
        room.lastEventTime = room.lastEvent.origin_server_ts;
      }
    }

    if (state.unread_notifications) {
      const notifications: UnreadNotifications = state.unread_notifications;
      room.unreadCount = notifications.notification_count;
      room.highlightCount = notifications.highlight_count;
    }

    return room;
  }

  getDisplayName(): string {
    if (this.name) {
      return this.name;
    }
    if (this.displayName) {
      return this.displayName;
    }
    return this.id;
  }
}

export class User implements MatrixUser {
  userId: string;
  displayName?: string;
  avatarUrl?: string;
  presence?: string;
  lastActiveAgo?: number;
  currentlyActive?: boolean;
  statusMsg?: string;

  constructor(userId: string) {
    this.userId = userId;
  }

  static fromPresenceEvent(
    sender: string,
    presence?: string,
    statusMsg?: string,
    lastActiveAgo?: number,
    currentlyActive?: boolean,
    avatarUrl?: string,
    displayname?: string
  ): User {
    const user = new User(sender);
    user.presence = presence;
    user.statusMsg = statusMsg;
    user.lastActiveAgo = lastActiveAgo;
    user.currentlyActive = currentlyActive;
    user.avatarUrl = avatarUrl;
    user.displayName = displayname;
    return user;
  }

  static fromProfile(userId: string, profile: ProfileData): User {
    const user = new User(userId);
    user.displayName = profile.displayname;
    user.avatarUrl = profile.avatar_url;
    return user;
  }

  getDisplayName(): string {
    if (this.displayName) {
      return this.displayName;
    }
    return this.userId;
  }

  getAvatarUrl(): string | undefined {
    return this.avatarUrl;
  }
}

export class Message {
  eventId: string;
  roomId: string;
  sender: string;
  type: string;
  content: Record<string, string | object>;
  timestamp: number;
  isOutgoing: boolean;
  status: MessageStatus;
  replyEventId?: string;
  editedEventId?: string;

  constructor(event: Event, isOutgoing: boolean = false) {
    this.eventId = event.event_id || '';
    this.roomId = event.room_id || '';
    this.sender = event.sender || '';
    this.type = event.type;
    this.content = event.content as Record<string, string | object>;
    this.timestamp = event.origin_server_ts || Date.now();
    this.isOutgoing = isOutgoing;
    this.status = MessageStatus.SENT;
  }

  static fromEvent(event: Event, currentUserId: string): Message {
    const isOutgoing: boolean = event.sender === currentUserId;
    return new Message(event, isOutgoing);
  }

  static createPendingMessage(
    roomId: string,
    content: Record<string, string | object>
  ): Message {
    const pendingEvent: Event = {
      type: 'm.room.message',
      content: content,
      event_id: '',
      sender: '',
      origin_server_ts: 0
    };
    const msg: Message = new Message(pendingEvent, true);
    msg.eventId = 'temp_' + Date.now();
    msg.roomId = roomId;
    msg.status = MessageStatus.SENDING;
    return msg;
  }

  getMessageBody(): string {
    const body: string | object | undefined = this.content?.['body'];
    if (body !== undefined) {
      return String(body);
    }
    return '';
  }

  getMessageType(): string {
    const msgtype: string | object | undefined = this.content?.['msgtype'];
    if (msgtype !== undefined) {
      return String(msgtype);
    }
    return 'm.text';
  }

  isTextMessage(): boolean {
    return this.getMessageType() === 'm.text';
  }

  isImageMessage(): boolean {
    return this.getMessageType() === 'm.image';
  }

  isFileMessage(): boolean {
    return this.getMessageType() === 'm.file';
  }
}

export { MessageStatus };
