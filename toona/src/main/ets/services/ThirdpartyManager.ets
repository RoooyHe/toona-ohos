import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  ThirdpartyProtocolsResponse,
  ThirdpartyUserResponse,
  ThirdpartyLocationResponse
} from '../models/MatrixTypes';

export class ThirdpartyManager {
  private static instance: ThirdpartyManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): ThirdpartyManager {
    if (!ThirdpartyManager.instance) {
      ThirdpartyManager.instance = new ThirdpartyManager();
    }
    return ThirdpartyManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('ThirdpartyManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async getProtocols(): Promise<ThirdpartyProtocolsResponse> {
    try {
      return await this.ensureHttpClient().getThirdpartyProtocols();
    } catch (error) {
      console.error('Failed to get thirdparty protocols:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thirdparty protocols: ${errMsg}`);
    }
  }

  async getProtocol(protocol: string): Promise<ThirdpartyProtocolsResponse> {
    try {
      return await this.ensureHttpClient().getThirdpartyProtocol(protocol);
    } catch (error) {
      console.error('Failed to get thirdparty protocol:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thirdparty protocol: ${errMsg}`);
    }
  }

  async searchUser(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyUserResponse> {
    try {
      return await this.ensureHttpClient().thirdpartyUserSearch(protocol, params);
    } catch (error) {
      console.error('Failed to search thirdparty user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search thirdparty user: ${errMsg}`);
    }
  }

  async discoverUser(params: Record<string, string | string[]>): Promise<ThirdpartyUserResponse> {
    try {
      return await this.ensureHttpClient().thirdpartyUserDiscovery(params);
    } catch (error) {
      console.error('Failed to discover thirdparty user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to discover thirdparty user: ${errMsg}`);
    }
  }

  async searchLocation(
    protocol: string,
    params: Record<string, string | string[]>
  ): Promise<ThirdpartyLocationResponse> {
    try {
      return await this.ensureHttpClient().thirdpartyLocationSearch(protocol, params);
    } catch (error) {
      console.error('Failed to search thirdparty location:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search thirdparty location: ${errMsg}`);
    }
  }

  async discoverLocation(params: Record<string, string | string[]>): Promise<ThirdpartyLocationResponse> {
    try {
      return await this.ensureHttpClient().thirdpartyLocationDiscovery(params);
    } catch (error) {
      console.error('Failed to discover thirdparty location:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to discover thirdparty location: ${errMsg}`);
    }
  }
}