import {
  User as MatrixUser,
  Room as MatrixRoom,
  MessageStatus,
  Event,
  LoginResponse,
  RoomSummary,
  UnreadNotifications
} from '../models/MatrixTypes';

interface LoginResponseData {
  user_id: string;
  home_server: string;
  device_id: string;
}

interface GeneratedTypeLiteralInterface_1 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_2 {
  events: Event[];
  limited?: boolean;
  prev_batch?: string;
}

interface RoomStateData {
  summary?: RoomSummary;
  state?: GeneratedTypeLiteralInterface_1;
  timeline?: GeneratedTypeLiteralInterface_2;
  unread_notifications?: UnreadNotifications;
}

interface PresenceEventContent {
  presence?: string;
  status_msg?: string;
  last_active_ago?: number;
  currently_active?: boolean;
  avatar_url?: string;
  displayname?: string;
}

interface PresenceEvent {
  sender: string;
  content?: PresenceEventContent;
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

  static fromLoginResponse(response: LoginResponse | LoginResponseData, accessToken: string): Session {
    const session = new Session();
    session.userId = response.user_id;
    session.accessToken = accessToken;
    session.homeServer = response.home_server;
    session.deviceId = response.device_id;
    return session;
  }

  toJSON(): Record<string, string> {
    return {
      "userId": this.userId,
      "accessToken": this.accessToken,
      "homeServer": this.homeServer,
      "deviceId": this.deviceId,
      "isGuest": this.isGuest.toString(),
      "nextBatch": this.nextBatch
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
  unreadCount?: number;
  highlightCount?: number;
  lastEvent?: Event;
  lastEventTime?: number;

  constructor(roomId: string) {
    this.id = roomId;
  }

  static fromMatrixRoomState(roomId: string, state: RoomStateData): Room {
    const room = new Room(roomId);
    room.myMembership = 'join';

    if (state.summary) {
      const summary = state.summary;
      if (summary.joined_member_count !== undefined) {
        room.memberCount = summary.joined_member_count;
      }
      if (summary.invited_member_count !== undefined) {
        room.memberCount = summary.invited_member_count;
      }
    }

    const stateEvents = state.state?.events || [];
    for (const event of stateEvents) {
      const content = event.content as Record<string, string | object>;
      switch (event.type) {
        case 'm.room.name':
          const nameVal = content['name'];
          if (nameVal !== undefined) {
            room.name = String(nameVal);
            room.displayName = String(nameVal);
          }
          break;
        case 'm.room.topic':
          const topicVal = content['topic'];
          if (topicVal !== undefined) {
            room.topic = String(topicVal);
          }
          break;
        case 'm.room.avatar':
          const avatarVal = content['url'];
          if (avatarVal !== undefined) {
            room.avatarUrl = String(avatarVal);
          }
          break;
        case 'm.room.canonical_alias':
          const aliasVal = content['alias'];
          if (aliasVal !== undefined) {
            room.name = String(aliasVal);
          }
          break;
      }
    }

    if (state.timeline?.events && state.timeline.events.length > 0) {
      room.lastEvent = state.timeline.events[state.timeline.events.length - 1];
      room.lastEventTime = room.lastEvent?.origin_server_ts;
    }

    if (state.unread_notifications) {
      room.unreadCount = state.unread_notifications.notification_count;
      room.highlightCount = state.unread_notifications.highlight_count;
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

  static fromPresenceEvent(event: PresenceEvent): User {
    const user = new User(event.sender);
    if (event.content) {
      user.presence = event.content.presence;
      user.statusMsg = event.content.status_msg;
      user.lastActiveAgo = event.content.last_active_ago;
      user.currentlyActive = event.content.currently_active;
      user.avatarUrl = event.content.avatar_url;
      user.displayName = event.content.displayname;
    }
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
    const isOutgoing = event.sender === currentUserId;
    return new Message(event, isOutgoing);
  }

  static createPendingMessage(roomId: string, content: Record<string, string | object>): Message {
    const msg = new Message({
      type: 'm.room.message',
      content: content
    } as Event, true);
    msg.eventId = 'temp_' + Date.now();
    msg.roomId = roomId;
    msg.status = MessageStatus.SENDING;
    return msg;
  }

  getMessageBody(): string {
    const body = this.content?.['body'];
    if (body !== undefined) {
      return String(body);
    }
    return '';
  }

  getMessageType(): string {
    const msgtype = this.content?.['msgtype'];
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
