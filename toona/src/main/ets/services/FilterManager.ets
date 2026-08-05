import { AppLogger } from '../utils/AppLogger';
import {
  Filter,
  CreateFilterResponse,
  GetFilterResponse,
  RoomFilterPart,
  PresenceFilter
} from '../models/MatrixTypes';
import { BaseHttpClient, HttpVersion } from '../network/clients/BaseHttpClient';

export class FilterManager {
  private httpClient: BaseHttpClient;
  private logger = AppLogger.getLogger(FilterManager);

  constructor(httpClient: BaseHttpClient) {
    this.httpClient = httpClient;
  }

  async createFilter(userId: string, filter: Filter, version: HttpVersion = 'v3'): Promise<CreateFilterResponse> {
    try {
      const encodedUserId = encodeURIComponent(userId);
      return await this.httpClient.request<CreateFilterResponse>(
        'POST',
        `/user/${encodedUserId}/filter`,
        filter as Record<string, string | object>,
        undefined,
        version
      );
    } catch (error) {
      this.logger.error('Failed to create filter:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to create filter: ${errMsg}`);
    }
  }

  async getFilter(userId: string, filterId: string, version: HttpVersion = 'v3'): Promise<GetFilterResponse> {
    try {
      const encodedUserId = encodeURIComponent(userId);
      const encodedFilterId = encodeURIComponent(filterId);
      return await this.httpClient.get<GetFilterResponse>(
        `/user/${encodedUserId}/filter/${encodedFilterId}`,
        undefined,
        version
      );
    } catch (error) {
      this.logger.error('Failed to get filter:', error);
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
