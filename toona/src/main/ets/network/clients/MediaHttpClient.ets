import http from '@ohos.net.http';
import { MediaUploadResponse, MediaConfig, UrlPreviewResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class MediaHttpClient extends BaseHttpClient {
  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ): Promise<MediaUploadResponse> {
    const url = this.buildMediaUrl('/upload');
    const headers: Record<string, string> = {
      'Content-Type': contentType
    };
    if (fileName) {
      headers['Content-Disposition'] = `attachment; filename="${fileName}"`;
    }

    console.info(`[HTTP] POST ${url}`);

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

      console.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        console.info(`[HTTP] Response body: ${result.result}`);
      }

      if (result.responseCode >= 200 && result.responseCode < 300) {
        if (typeof result.result === 'string' && result.result.length > 0) {
          return JSON.parse(result.result) as MediaUploadResponse;
        }
        return { content_uri: '' } as MediaUploadResponse;
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

  async downloadMedia(serverName: string, mediaId: string): Promise<ArrayBuffer> {
    const encodedServerName = encodeURIComponent(serverName);
    const encodedMediaId = encodeURIComponent(mediaId);
    const url = this.buildMediaUrl(`/download/${encodedServerName}/${encodedMediaId}`);

    console.info(`[HTTP] GET ${url}`);

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

      console.info(`[HTTP] Response code: ${result.responseCode}`);

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

    console.info(`[HTTP] GET ${url}`);

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

      console.info(`[HTTP] Response code: ${result.responseCode}`);

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

    console.info(`[HTTP] GET ${fullUrl}`);

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

      console.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        console.info(`[HTTP] Response body: ${result.result}`);
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

    console.info(`[HTTP] GET ${url}`);

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

      console.info(`[HTTP] Response code: ${result.responseCode}`);
      if (typeof result.result === 'string' && result.result.length > 0) {
        console.info(`[HTTP] Response body: ${result.result}`);
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
