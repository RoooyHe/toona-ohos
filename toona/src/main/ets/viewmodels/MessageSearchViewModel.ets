import { Message, Room } from '../models/DataModels';
import { IRoomManager } from '../services/RoomManager';
import { IMessageManager } from '../services/MessageManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('MessageSearchViewModel');

export interface SearchResultMessage {
  eventId: string;
  sender: string;
  body: string;
  timestamp: number;
}

export interface SearchResult {
  roomId: string;
  roomName: string;
  messages: SearchResultMessage[];
}

export interface MessageSearchState {
  searchQuery: string;
  searchResults: SearchResult[];
  isSearching: boolean;
  hasSearched: boolean;
}

export type MessageSearchStateCallback = (state: MessageSearchState) => void;
export type NavigateToMessageCallback = (roomId: string, eventId: string) => void;

export class MessageSearchViewModel {
  private roomManager: IRoomManager;
  private messageManager: IMessageManager;
  private state: MessageSearchState;
  private onStateChanged: MessageSearchStateCallback | null = null;
  private onNavigateToMessage: NavigateToMessageCallback | null = null;

  constructor(roomManager: IRoomManager, messageManager: IMessageManager) {
    this.roomManager = roomManager;
    this.messageManager = messageManager;
    this.state = {
      searchQuery: '',
      searchResults: [],
      isSearching: false,
      hasSearched: false
    };
  }

  setOnStateChanged(callback: MessageSearchStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnNavigateToMessage(callback: NavigateToMessageCallback): void {
    this.onNavigateToMessage = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): MessageSearchState {
    return this.state;
  }

  setSearchQuery(value: string): void {
    this.state.searchQuery = value;
    this.notifyStateChanged();
  }

  async search(): Promise<void> {
    if (!this.state.searchQuery.trim()) {
      return;
    }

    this.state.isSearching = true;
    this.state.hasSearched = true;
    this.notifyStateChanged();

    try {
      const rooms: Room[] = await this.roomManager.getRooms();
      const results: SearchResult[] = [];

      for (const room of rooms) {
        if (room.isSpace) {
          continue;
        }

        try {
          const messages: Message[] = await this.messageManager.getMessages(room.id, 50);
          const matchingMessages: Message[] = messages.filter((msg: Message): boolean => {
            const body: string = msg.getMessageBody().toLowerCase();
            return body.includes(this.state.searchQuery.toLowerCase());
          });

          if (matchingMessages.length > 0) {
            const searchMsgs: SearchResultMessage[] = matchingMessages.map((msg: Message): SearchResultMessage => {
              const result: SearchResultMessage = {
                eventId: msg.eventId,
                sender: msg.sender,
                body: msg.getMessageBody(),
                timestamp: msg.timestamp
              };
              return result;
            });
            const item: SearchResult = {
              roomId: room.id,
              roomName: room.getDisplayName(),
              messages: searchMsgs
            };
            results.push(item);
          }
        } catch (error) {
          logger.error('Failed to search in room ' + room.id + ':', error);
        }
      }

      this.state.searchResults = results;
    } catch (error) {
      logger.error('Search failed:', error);
      ToastUtils.show('Search failed');
    } finally {
      this.state.isSearching = false;
      this.notifyStateChanged();
    }
  }

  navigateToMessage(roomId: string, eventId: string): void {
    if (this.onNavigateToMessage) {
      this.onNavigateToMessage(roomId, eventId);
    }
  }
}
