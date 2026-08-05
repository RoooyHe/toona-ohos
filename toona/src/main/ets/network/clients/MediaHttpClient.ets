import { MediaUploadResponse, MediaConfig, UrlPreviewResponse } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class MediaHttpClient extends BaseHttpClient {
  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ): Promise<MediaUploadResponse> {
    let endpoint = '/_matrix/media/v3/upload';
    if (fileName) {
      endpoint += `?filename=${encodeURIComponent(fileName)}`;
    }
    return await this.upload<MediaUploadResponse>(endpoint, data, contentType, fileName || 'media');
  }

  async downloadMedia(serverName: string, mediaId: string): Promise<ArrayBuffer> {
    const encodedServerName = encodeURIComponent(serverName);
    const encodedMediaId = encodeURIComponent(mediaId);
    const url = this.buildMediaUrl(`/download/${encodedServerName}/${encodedMediaId}`);
    return await this.requestBinary(url);
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
    return await this.requestBinary(url);
  }

  async getUrlPreview(url: string, ts?: number): Promise<UrlPreviewResponse> {
    const queryParams: Record<string, string | number> = { "url": url };
    if (ts !== undefined) {
      queryParams['ts'] = ts;
    }
    return await this.requestMediaJson<UrlPreviewResponse>('/preview_url', queryParams);
  }

  async getMediaConfig(): Promise<MediaConfig> {
    return await this.requestMediaJson<MediaConfig>('/config');
  }
}
