import http from '@ohos.net.http';
import { MediaUploadResponse, MediaConfig, UrlPreviewResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class MediaHttpClient extends BaseHttpClient {
  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ): Promise<MediaUploadResponse> {
    // 构建上传路径
    let endpoint = '/_matrix/media/v3/upload';
    if (fileName) {
      endpoint += `?filename=${encodeURIComponent(fileName)}`;
    }

    // 这里调用父类的 upload，它会自动处理 Token
    return await this.upload<MediaUploadResponse>(endpoint, data, contentType, fileName || 'media');
  }

  async downloadMedia(serverName: string, mediaId: string): Promise<ArrayBuffer> {
    const encodedServerName = encodeURIComponent(serverName);
    const encodedMediaId = encodeURIComponent(mediaId);
    const url = this.buildMediaUrl(`/download/${encodedServerName}/${encodedMediaId}`);

    this.logger.info(`GET `);

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.GET,
          header: {},
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
      } else {
        throw new Error(`HTTP ${result.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async getThumbnail(
    serverName: string,
    mediaId: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale',
    animated?: boolean
  ): Promise<ArrayBuffer> {
    const encodedServerName = encodeURIComponent(serverName);
    const encodedMediaId = encodeURIComponent(mediaId);
    const queryParams: Record<string, string | number> = {
      "width": width,
      "height": height
    };
    if (method) {
      queryParams['method'] = method;
    }
    if (animated !== undefined) {
      queryParams['animated'] = animated ? 'true' : 'false';
    }
    const url = this.buildMediaUrl(`/thumbnail/${encodedServerName}/${encodedMediaId}`, queryParams);

    this.logger.info(`GET `);

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.GET,
          header: {},
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
      } else {
        throw new Error(`HTTP ${result.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async getUrlPreview(url: string, ts?: number): Promise<UrlPreviewResponse> {
    const queryParams: Record<string, string | number> = { "url": url };
    if (ts !== undefined) {
      queryParams['ts'] = ts;
    }
    const endpoint = '/preview_url';
    const fullUrl = this.buildMediaUrl(endpoint, queryParams);

    this.logger.info(`[HTTP] GET ${fullUrl}`);

    const headers: Record<string, string> = {};
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    const httpRequest = http.createHttp();

    try {
      const result = await new Promise<http.HttpResponse>((resolve, reject) => {
        const options: http.HttpRequestOptions = {
          method: http.RequestMethod.GET,
          header: headers,
          expectDataType: http.HttpDataType.STRING
        };

        httpRequest.request(fullUrl, options, (err, data) => {
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
          return JSON.parse(result.result) as UrlPreviewResponse;
        }
        return {} as UrlPreviewResponse;
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

  async getMediaConfig(): Promise<MediaConfig> {
    const url = this.buildMediaUrl('/config');

    this.logger.info(`GET `);

    const headers: Record<string, string> = {};
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

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
          return JSON.parse(result.result) as MediaConfig;
        }
        return {} as MediaConfig;
      } else {
        throw new Error(`HTTP ${result.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}
