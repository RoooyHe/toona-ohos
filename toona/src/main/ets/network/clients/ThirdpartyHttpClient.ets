import {
  ThirdpartyProtocolsResponse,
  ThirdpartyUserResponse,
  ThirdpartyLocationResponse
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class ThirdpartyHttpClient extends BaseHttpClient {
  async getThirdpartyProtocols(): Promise<ThirdpartyProtocolsResponse> {
    return await this.get<ThirdpartyProtocolsResponse>('/thirdparty/protocols');
  }

  async getThirdpartyProtocol(protocol: string): Promise<ThirdpartyProtocolsResponse> {
    const encodedProtocol = encodeURIComponent(protocol);
    return await this.get<ThirdpartyProtocolsResponse>(`/thirdparty/protocol/${encodedProtocol}`);
  }

  async thirdpartyUserSearch(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyUserResponse> {
    const encodedProtocol = encodeURIComponent(protocol);
    return await this.get<ThirdpartyUserResponse>(
      `/thirdparty/user/${encodedProtocol}`,
      params as Record<string, string | number>
    );
  }

  async thirdpartyUserDiscovery(params: Record<string, string | string[]>): Promise<ThirdpartyUserResponse> {
    return await this.post<ThirdpartyUserResponse>('/thirdparty/user/', params);
  }

  async thirdpartyLocationSearch(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyLocationResponse> {
    const encodedProtocol = encodeURIComponent(protocol);
    return await this.get<ThirdpartyLocationResponse>(
      `/thirdparty/location/${encodedProtocol}`,
      params as Record<string, string | number>
    );
  }

  async thirdpartyLocationDiscovery(params: Record<string, string | string[]>): Promise<ThirdpartyLocationResponse> {
    return await this.post<ThirdpartyLocationResponse>('/thirdparty/location/', params);
  }
}
