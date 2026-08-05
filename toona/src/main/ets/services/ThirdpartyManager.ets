import { AppLogger } from '../utils/AppLogger';
import {
  ThirdpartyProtocolsResponse,
  ThirdpartyUserResponse,
  ThirdpartyLocationResponse
} from '../models/MatrixTypes';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

export class ThirdpartyManager {
  private logger = AppLogger.getLogger(ThirdpartyManager);
  private httpClient: BaseHttpClient;

  constructor(httpClient: BaseHttpClient) {
    this.httpClient = httpClient;
  }

  async getProtocols(): Promise<ThirdpartyProtocolsResponse> {
    try {
      return await this.httpClient.get<ThirdpartyProtocolsResponse>('/thirdparty/protocols');
    } catch (error) {
      this.logger.error('Failed to get thirdparty protocols:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thirdparty protocols: ${errMsg}`);
    }
  }

  async getProtocol(protocol: string): Promise<ThirdpartyProtocolsResponse> {
    try {
      const encodedProtocol = encodeURIComponent(protocol);
      return await this.httpClient.get<ThirdpartyProtocolsResponse>(`/thirdparty/protocol/${encodedProtocol}`);
    } catch (error) {
      this.logger.error('Failed to get thirdparty protocol:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thirdparty protocol: ${errMsg}`);
    }
  }

  async searchUser(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyUserResponse> {
    try {
      const encodedProtocol = encodeURIComponent(protocol);
      return await this.httpClient.get<ThirdpartyUserResponse>(
        `/thirdparty/user/${encodedProtocol}`,
        params as Record<string, string | number>
      );
    } catch (error) {
      this.logger.error('Failed to search thirdparty user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search thirdparty user: ${errMsg}`);
    }
  }

  async discoverUser(params: Record<string, string | string[]>): Promise<ThirdpartyUserResponse> {
    try {
      return await this.httpClient.post<ThirdpartyUserResponse>('/thirdparty/user/', params);
    } catch (error) {
      this.logger.error('Failed to discover thirdparty user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to discover thirdparty user: ${errMsg}`);
    }
  }

  async searchLocation(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyLocationResponse> {
    try {
      const encodedProtocol = encodeURIComponent(protocol);
      return await this.httpClient.get<ThirdpartyLocationResponse>(
        `/thirdparty/location/${encodedProtocol}`,
        params as Record<string, string | number>
      );
    } catch (error) {
      this.logger.error('Failed to search thirdparty location:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search thirdparty location: ${errMsg}`);
    }
  }

  async discoverLocation(params: Record<string, string | string[]>): Promise<ThirdpartyLocationResponse> {
    try {
      return await this.httpClient.post<ThirdpartyLocationResponse>('/thirdparty/location/', params);
    } catch (error) {
      this.logger.error('Failed to discover thirdparty location:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to discover thirdparty location: ${errMsg}`);
    }
  }
}
