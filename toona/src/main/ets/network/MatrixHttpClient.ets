import http from '@ohos.net.http';

export class MatrixHttpClient {
  private baseUrl: string;
  private accessToken: string | null = null;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
  }

  setAccessToken(token: string | null): void {
    this.accessToken = token;
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  private buildUrl(endpoint: string, queryParams?: Record<string, string | number>, version: 'v3' | 'r0' | 'v1' = 'v3'): string {
    let url = `${this.baseUrl}/_matrix/client/${version}${endpoint}`;
    if (queryParams) {
      const keys = Object.keys(queryParams);
      if (keys.length > 0) {
        const queryString = keys.map(key => {
          const value = queryParams[key];
          return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`;
        }).join('&');
        url += `?${queryString}`;
      }
    }
    return url;
  }

  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }
    return headers;
  }

  async request<T>(
    method: string,
    endpoint: string,
    body?: Record<string, string | object>,
    queryParams?: Record<string, string | number>,
    version: 'v3' | 'r0' | 'v1' = 'v3'
  ): Promise<T> {
    const url = this.buildUrl(endpoint, queryParams, version);
    const headers = this.buildHeaders();
    const requestBody = body ? JSON.stringify(body) : undefined;

    console.info(`[HTTP] ${method} ${url}`);
    if (requestBody) {
      console.info(`[HTTP] Request body: ${requestBody}`);
    }

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: method as http.RequestMethod,
          header: headers,
          extraData: requestBody,
          expectDataType: http.HttpDataType.STRING
        };

        httpRequest.request(url, options, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });

      console.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        console.info(`[HTTP] Response body: ${result.result}`);
      }

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as T;
        }
        return Object() as T;
      } else {
        let errcode: string = 'UNKNOWN';
        let errorMsg: string = '';
        try {
          if (typeof result.result === 'string') {
            const parsed: Record<string, string> = JSON.parse(result.result) as Record<string, string>;
            errcode = parsed['errcode'] || 'UNKNOWN';
            errorMsg = parsed['error'] || '';
          } else {
            errcode = 'UNKNOWN';
            errorMsg = String(result.result);
          }
        } catch {
          errcode = 'PARSE_ERROR';
          errorMsg = 'Failed to parse error response';
        }
        throw new Error(`${errcode}: ${errorMsg}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async get<T>(endpoint: string, queryParams?: Record<string, string | number>, version: 'v3' | 'r0' | 'v1' = 'v3'): Promise<T> {
    return this.request<T>('GET', endpoint, undefined, queryParams, version);
  }

  async getWithoutVersionPrefix<T>(endpoint: string): Promise<T> {
    const url = `${this.baseUrl}/_matrix/client${endpoint}`;
    const headers = this.buildHeaders();
    
    console.info(`[HTTP] GET ${url}`);
    
    const httpRequest = http.createHttp();
    const result = await new Promise<http.HttpResponse>((resolve, reject) => {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.STRING
      };
      httpRequest.request(url, options, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
    
    console.info(`[HTTP] Response code: ${result.responseCode}`);
    if (typeof result.result === 'string' && result.result.length > 0) {
      console.info(`[HTTP] Response body: ${result.result}`);
    }
    
    if (result.responseCode >= 200 && result.responseCode < 300) {
      if (typeof result.result === 'string' && result.result.length > 0) {
        return JSON.parse(result.result) as T;
      }
      return Object() as T;
    }
    throw new Error(`HTTP ${result.responseCode}`);
  }

  async post<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('POST', endpoint, body);
  }

  async put<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('PUT', endpoint, body);
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>('DELETE', endpoint);
  }

  async upload<T>(
    endpoint: string,
    data: ArrayBuffer,
    contentType: string,
    fileName: string
  ): Promise<T> {
    const url = this.buildUrl(endpoint);
    const headers = this.buildHeaders();
    headers['Content-Type'] = contentType;
    headers['Content-Disposition'] = `attachment; filename="${fileName}"`;

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.PUT,
          header: headers,
          extraData: data,
          expectDataType: http.HttpDataType.STRING
        };

        httpRequest.request(url, options, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as T;
        }
        return Object() as T;
      } else {
        let errcode: string = 'UNKNOWN';
        let errorMsg: string = '';
        try {
          if (typeof result.result === 'string') {
            const parsed: Record<string, string> = JSON.parse(result.result) as Record<string, string>;
            errcode = parsed['errcode'] || 'UNKNOWN';
            errorMsg = parsed['error'] || '';
          } else {
            errcode = 'UNKNOWN';
            errorMsg = String(result.result);
          }
        } catch {
          errcode = 'PARSE_ERROR';
          errorMsg = 'Failed to parse error response';
        }
        throw new Error(`${errcode}: ${errorMsg}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}

export class MatrixConfig {
  private static instance: MatrixConfig;
  private homeserverUrl: string = '';
  private _httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): MatrixConfig {
    if (!MatrixConfig.instance) {
      MatrixConfig.instance = new MatrixConfig();
    }
    return MatrixConfig.instance;
  }

  setHomeserver(url: string): void {
    this.homeserverUrl = url;
    this._httpClient = new MatrixHttpClient(url);
  }

  getHomeserver(): string {
    return this.homeserverUrl;
  }

  getHttpClient(): MatrixHttpClient {
    if (!this._httpClient) {
      throw new Error('MatrixConfig not initialized. Call setHomeserver first.');
    }
    return this._httpClient;
  }

  clear(): void {
    this.homeserverUrl = '';
    this._httpClient = null;
  }
}

export function createMatrixClient(homeserverUrl: string): MatrixHttpClient {
  MatrixConfig.getInstance().setHomeserver(homeserverUrl);
  return MatrixConfig.getInstance().getHttpClient();
}
