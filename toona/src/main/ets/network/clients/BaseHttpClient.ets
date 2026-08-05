import http from '@ohos.net.http';
import { AppLogger } from '../../utils/AppLogger';
import { ConnectionConfig } from '../ConnectionConfig';


export type HttpVersion = 'v3' | 'r0' | 'v1';

export class BaseHttpClient {
  protected logger = AppLogger.getLogger(BaseHttpClient);
  protected config: ConnectionConfig;

  constructor(config: ConnectionConfig) {
    this.config = config;
  }

  public getBaseUrl(): string {
    return this.config.getHomeserver().replace(/\/$/, '');
  }

  protected getAccessToken(): string | null {
    return this.config.getAccessToken();
  }

  public buildMediaUrl(endpoint: string, queryParams?: Record<string, string | number>): string {
    const baseUrl = this.getBaseUrl();
    let url = `${baseUrl}/_matrix/media/v3${endpoint}`;
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

  public buildUrl(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): string {
    const baseUrl = this.getBaseUrl();
    this.logger.info('BaseHttpClient: buildUrl called, baseUrl: ' + baseUrl + ', endpoint: ' + endpoint);
    let url = `${baseUrl}/_matrix/client/${version}${endpoint}`;
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

  public buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    const token = this.getAccessToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  public async request<T>(
    method: string,
    endpoint: string,
    body?: Record<string, string | object>,
    queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'
  ): Promise<T> {
    const url = this.buildUrl(endpoint, queryParams, version);
    const headers = this.buildHeaders();
    const requestBody = body ? JSON.stringify(body) : undefined;

    this.logger.info(`[HTTP] ${method} ${url}`);
    if (requestBody) {
      this.logger.info(`[HTTP] Request body: ${requestBody}`);
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

      this.logger.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        this.logger.info(`[HTTP] Response body: ${result.result}`);
      }

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as T;
        }
        return Object() as T;
      } else {
        let errcode: string = 'UNKNOWN';
        let errorMsg: string = '';
        let session: string = '';

        try {
          if (typeof result.result === 'string') {
            const parsed: Record<string, Object> = JSON.parse(result.result) as Record<string, Object>;
            errcode = (parsed['errcode'] as string) || 'UNKNOWN';
            errorMsg = (parsed['error'] as string) || '';
            session = (parsed['session'] as string) || '';
          } else {
            errcode = 'UNKNOWN';
            errorMsg = String(result.result);
          }
        } catch {
          errcode = 'PARSE_ERROR';
          errorMsg = 'Failed to parse error response';
        }

        if (result.responseCode === 401 && session) {
          throw new Error(`UIA_REQUIRED:${session}`);
        }

        throw new Error(`${errcode}: ${errorMsg}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  public async get<T>(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): Promise<T> {
    return this.request<T>('GET', endpoint, undefined, queryParams, version);
  }

  public async getWithoutVersionPrefix<T>(endpoint: string): Promise<T> {
    const baseUrl = this.getBaseUrl();
    const url = `${baseUrl}/_matrix/client${endpoint}`;
    const headers = this.buildHeaders();

    this.logger.info(`[HTTP] GET ${url}`);

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

    this.logger.info(`[HTTP] Response code: ${result.responseCode}`);
    if (typeof result.result === 'string' && result.result.length > 0) {
      this.logger.info(`[HTTP] Response body: ${result.result}`);
    }

    if (result.responseCode >= 200 && result.responseCode < 300) {
      if (typeof result.result === 'string' && result.result.length > 0) {
        return JSON.parse(result.result) as T;
      }
      return Object() as T;
    }
    throw new Error(`HTTP ${result.responseCode}`);
  }

  public async post<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('POST', endpoint, body);
  }

  public async put<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('PUT', endpoint, body);
  }

  public async delete<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('DELETE', endpoint, body);
  }

  public async requestBinary(
    url: string,
    headers?: Record<string, string>
  ): Promise<ArrayBuffer> {
    const requestHeaders: Record<string, string> = headers || this.buildHeaders();

    this.logger.info(`[HTTP] GET BINARY ${url}`);

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.GET,
          header: requestHeaders,
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        };
        httpRequest.request(url, options, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });

      this.logger.info(`[HTTP] Response code: ${result.responseCode}`);

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (result.result instanceof ArrayBuffer) {
          return result.result;
        }
        return new ArrayBuffer(0);
      }
      throw new Error(`HTTP ${result.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }

  public async requestMediaJson<T>(
    endpoint: string,
    queryParams?: Record<string, string | number>
  ): Promise<T> {
    const url = this.buildMediaUrl(endpoint, queryParams);
    const headers = this.buildHeaders();

    this.logger.info(`[HTTP] GET ${url}`);

    const httpRequest = http.createHttp();

    try {
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

      this.logger.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        this.logger.info(`[HTTP] Response body: ${result.result}`);
      }

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as T;
        }
        return Object() as T;
      }
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
    } finally {
      httpRequest.destroy();
    }
  }

  public async upload<T>(
    endpoint: string,
    data: ArrayBuffer,
    contentType: string,
    fileName: string
  ): Promise<T> {
    const baseUrl = this.getBaseUrl();
    let url = endpoint.startsWith('http') ? endpoint : `${baseUrl}${endpoint}`;

    const headers = this.buildHeaders();
    headers['Content-Type'] = contentType;

    if (!url.includes('filename=')) {
      url += `?filename=${encodeURIComponent(fileName)}`;
    }

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.POST,
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

      this.logger.info(`[HTTP] POST MEDIA ${url} - Status: ${result.responseCode}`);

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as T;
        }
        return Object() as T;
      } else {
        let errcode = 'UNKNOWN';
        let errorMsg = String(result.result);
        try {
          if (typeof result.result === 'string') {
            const parsed = JSON.parse(result.result) as Record<string, string>;
            errcode = parsed['errcode'] || 'UNKNOWN';
            errorMsg = parsed['error'] || errorMsg;
          }
        } catch (e) {
        }
        throw new Error(`${errcode}: ${errorMsg}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}
