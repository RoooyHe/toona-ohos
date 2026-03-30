import { Filter, CreateFilterResponse, GetFilterResponse } from '../../models/MatrixTypes';
import { BaseHttpClient, HttpVersion } from './BaseHttpClient';

export class FilterHttpClient extends BaseHttpClient {
  async createFilter(userId: string, filter: Filter, version: HttpVersion = 'v3'): Promise<CreateFilterResponse> {
    const encodedUserId = encodeURIComponent(userId);
    return await this.request<CreateFilterResponse>(
      'POST',
      `/user/${encodedUserId}/filter`,
      filter as Record<string, string | object>,
      undefined,
      version
    );
  }

  async getFilter(userId: string, filterId: string, version: HttpVersion = 'v3'): Promise<GetFilterResponse> {
    const encodedUserId = encodeURIComponent(userId);
    const encodedFilterId = encodeURIComponent(filterId);
    return await this.get<GetFilterResponse>(
      `/user/${encodedUserId}/filter/${encodedFilterId}`,
      undefined,
      version
    );
  }
}
