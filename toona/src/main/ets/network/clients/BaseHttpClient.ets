import http from '@ohos.net.http';

export type HttpVersion = 'v3' | 'r0' | 'v1';

export class BaseHttpClient {
  protected baseUrl: string;
  protected mediaBaseUrl: string;
  protected accessToken: string | null = null;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.mediaBaseUrl = baseUrl.replace(/\/$/, '') + '/_matrix/media/v3';
  }

  setAccessToken(token: string | null): void {
    this.accessToken = token;
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  public buildMediaUrl(endpoint: string, queryParams?: Record<string, string | number>): string {
    let url = `${this.mediaBaseUrl}${endpoint}`;
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
    console.info('BaseHttpClient: buildUrl called, baseUrl: ' + this.baseUrl + ', endpoint: ' + endpoint);
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

  public buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
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
        let session: string = ''; // ✅ 新增：提取 Session

        try {
          if (typeof result.result === 'string') {
            // ✅ 使用 Record<string, Object> 解析，确保兼容 UIA 的复杂结构
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

        // ✅ 核心修复：如果是 401 且含有 session，说明是 UIA 安全验证，抛出特定标识
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

  public async post<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('POST', endpoint, body);
  }

  public async put<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('PUT', endpoint, body);
  }

  // ✅ 修复：让 DELETE 方法也支持传递 Body 参数（UIA 密码验证必须放入 Body）
  public async delete<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.request<T>('DELETE', endpoint, body);
  }

  public async upload<T>(
    endpoint: string,
    data: ArrayBuffer,
    contentType: string,
    fileName: string
  ): Promise<T> {
    // ✅ 修复 1：媒体上传必须使用 _matrix/media/v3 的基础 URL
    // 如果你之前的 endpoint 只是 '/upload'，我们需要拼接完整的媒体路径
    let url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}/_matrix/media/v3${endpoint}`;

    // ✅ 修复 2：调用 buildHeaders，它会自动注入 Authorization: Bearer {token}
    const headers = this.buildHeaders();
    headers['Content-Type'] = contentType;

    // Matrix 要求带上 filename 参数在 URL 中，但这取决于你的 MediaHttpClient 怎么传
    // 标准做法是在查询参数中加上 ?filename=...
    if (!url.includes('filename=')) {
      url += `?filename=${encodeURIComponent(fileName)}`;
    }

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.POST, // ✅ 媒体上传是 POST 请求
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

      console.info(`[HTTP] POST MEDIA ${url} - Status: ${result.responseCode}`);

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
          // 解析失败忽略
        }
        throw new Error(`${errcode}: ${errorMsg}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}