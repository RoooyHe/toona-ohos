import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  Filter,
  CreateFilterResponse,
  GetFilterResponse,
  RoomFilterPart,
  PresenceFilter
} from '../models/MatrixTypes';

export class FilterManager {
  private static instance: FilterManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): FilterManager {
    if (!FilterManager.instance) {
      FilterManager.instance = new FilterManager();
    }
    return FilterManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('FilterManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async createFilter(userId: string, filter: Filter, version: 'v3' | 'r0' = 'v3'): Promise<CreateFilterResponse> {
    try {
      return await this.ensureHttpClient().createFilter(userId, filter, version);
    } catch (error) {
      console.error('Failed to create filter:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to create filter: ${errMsg}`);
    }
  }

  async getFilter(userId: string, filterId: string, version: 'v3' | 'r0' = 'v3'): Promise<GetFilterResponse> {
    try {
      return await this.ensureHttpClient().getFilter(userId, filterId, version);
    } catch (error) {
      console.error('Failed to get filter:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get filter: ${errMsg}`);
    }
  }

  async createRoomFilter(userId: string, roomFilter: RoomFilterPart, version: 'v3' | 'r0' = 'v3'): Promise<CreateFilterResponse> {
    const filter: Filter = { room: roomFilter };
    return this.createFilter(userId, filter, version);
  }

  async createPresenceFilter(userId: string, presenceFilter: PresenceFilter, version: 'v3' | 'r0' = 'v3'): Promise<CreateFilterResponse> {
    const filter: Filter = { presence: presenceFilter };
    return this.createFilter(userId, filter, version);
  }

  async createSyncFilter(userId: string, filterFields: Filter): Promise<CreateFilterResponse> {
    return this.createFilter(userId, filterFields, 'v3');
  }
}