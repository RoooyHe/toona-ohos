import http from '@ohos.net.http';
import { AppLogger } from '../../utils/AppLogger';
import { ConnectionConfig } from '../ConnectionConfig';

export type HttpVersion = 'v3' | 'r0' | 'v1' | '';

enum ErrorParseMode {
  FULL,
  MINIMAL
}

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
      url = this.appendQueryString(url, queryParams);
    }
    return url;
  }

  public buildUrl(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): string {
    const baseUrl = this.getBaseUrl();
    const versionPath: string = version ? `/${version}` : '';
    let url = `${baseUrl}/_matrix/client${versionPath}${endpoint}`;
    if (queryParams) {
      url = this.appendQueryString(url, queryParams);
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

  protected encodePath(...segments: string[]): string {
    return segments.map((s: string) => encodeURIComponent(s)).join('/');
  }

  protected buildQueryParams(params: Record<string, string | number | undefined>): Record<string, string | number> {
    const result: Record<string, string | number> = {};
    const keys = Object.keys(params);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = params[key];
      if (value !== undefined) {
        result[key] = value;
      }
    }
    return result;
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
    return this.executeRequest<T>(url, method, headers, requestBody, http.HttpDataType.STRING, ErrorParseMode.FULL);
  }

  public async get<T>(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): Promise<T> {
    return this.request<T>('GET', endpoint, undefined, queryParams, version);
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
    const result = await this.executeRawRequest(url, http.RequestMethod.GET, requestHeaders, undefined, http.HttpDataType.ARRAY_BUFFER);
    if (result.result instanceof ArrayBuffer) {
      return result.result;
    }
    return new ArrayBuffer(0);
  }

  public async requestMediaJson<T>(
    endpoint: string,
    queryParams?: Record<string, string | number>
  ): Promise<T> {
    const url = this.buildMediaUrl(endpoint, queryParams);
    const headers = this.buildHeaders();
    const requestBody: string | undefined = undefined;
    return this.executeRequest<T>(url, 'GET', headers, requestBody, http.HttpDataType.STRING, ErrorParseMode.FULL);
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
    return this.executeUpload<T>(url, headers, data);
  }

  private async executeRequest<T>(
    url: string,
    method: string,
    headers: Record<string, string>,
    body: string | undefined,
    expectDataType: http.HttpDataType,
    errorParseMode: ErrorParseMode
  ): Promise<T> {
    const methodLabel: string = method;
    this.logger.info(`[HTTP] ${methodLabel} ${url}`);
    if (body) {
      this.logger.info(`[HTTP] Request body: ${body}`);
    }

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: method as http.RequestMethod,
          header: headers,
          extraData: body,
          expectDataType: expectDataType
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

      throw this.parseHttpError(result, errorParseMode);
    } finally {
      httpRequest.destroy();
    }
  }

  private async executeRawRequest(
    url: string,
    method: http.RequestMethod,
    headers: Record<string, string>,
    body: string | ArrayBuffer | undefined,
    expectDataType: http.HttpDataType
  ): Promise<http.HttpResponse> {
    this.logger.info(`[HTTP] ${method} ${url}`);
    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: method,
          header: headers,
          extraData: body,
          expectDataType: expectDataType
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
        return result;
      }
      throw new Error(`HTTP ${result.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }

  private async executeUpload<T>(
    url: string,
    headers: Record<string, string>,
    data: ArrayBuffer
  ): Promise<T> {
    this.logger.info(`[HTTP] POST MEDIA ${url}`);
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
      }

      let errcode: string = 'UNKNOWN';
      let errorMsg: string = String(result.result);
      try {
        if (typeof result.result === 'string') {
          const parsed = JSON.parse(result.result) as Record<string, string>;
          errcode = parsed['errcode'] || 'UNKNOWN';
          errorMsg = parsed['error'] || errorMsg;
        }
      } catch (e) {
      }
      throw new Error(`${errcode}: ${errorMsg}`);
    } finally {
      httpRequest.destroy();
    }
  }

  private parseHttpError(result: http.HttpResponse, mode: ErrorParseMode): Error {
    if (mode === ErrorParseMode.MINIMAL) {
      return new Error(`HTTP ${result.responseCode}`);
    }

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
    } catch (e) {
      errcode = 'PARSE_ERROR';
      errorMsg = 'Failed to parse error response';
    }

    if (result.responseCode === 401 && session) {
      throw new Error(`UIA_REQUIRED:${session}`);
    }

    return new Error(`${errcode}: ${errorMsg}`);
  }

  private appendQueryString(url: string, queryParams: Record<string, string | number>): string {
    const keys = Object.keys(queryParams);
    if (keys.length === 0) {
      return url;
    }
    const queryString = keys.map((key: string) => {
      const value = queryParams[key];
      return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`;
    }).join('&');
    return `${url}?${queryString}`;
  }
}
