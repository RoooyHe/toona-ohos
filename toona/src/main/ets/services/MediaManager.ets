import { AppLogger } from '../utils/AppLogger';
import { MediaUploadResponse, MediaConfig as MediaConfigResponse, UrlPreviewResponse } from '../models/MatrixTypes';
import { MxcUtils } from '../utils/MxcUtils';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

interface ParsedMxcUri {
  serverName: string;
  mediaId: string;
}

export interface IMediaManager {
  uploadImage(data: ArrayBuffer, fileName: string): Promise<string>;
  uploadAudio(data: ArrayBuffer, fileName: string): Promise<string>;
  uploadVideo(data: ArrayBuffer, fileName: string): Promise<string>;
  uploadFile(data: ArrayBuffer, fileName: string, mimeType?: string): Promise<string>;
  getHttpUrl(mxcUri: string): string;
  getThumbnailUrl(mxcUri: string, width: number, height: number, method?: 'crop' | 'scale'): string;
}

export class MediaManager implements IMediaManager {
  private baseClient: BaseHttpClient;
  private logger = AppLogger.getLogger(MediaManager);

  constructor(baseClient: BaseHttpClient) {
    this.baseClient = baseClient;
  }

  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ): Promise<MediaUploadResponse> {
    try {
      let endpoint = '/_matrix/media/v3/upload';
      if (fileName) {
        endpoint += `?filename=${encodeURIComponent(fileName)}`;
      }
      return await this.baseClient.upload<MediaUploadResponse>(endpoint, data, contentType, fileName || 'media');
    } catch (error) {
      this.logger.error('Failed to upload media:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload media: ${errMsg}`);
    }
  }

  async uploadImage(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'image/jpeg', fileName);
    return response.content_uri;
  }

  async uploadAudio(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'audio/mp4', fileName);
    return response.content_uri;
  }

  async uploadVideo(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'video/mp4', fileName);
    return response.content_uri;
  }

  async uploadFile(data: ArrayBuffer, fileName: string,
    mimeType: string = 'application/octet-stream'): Promise<string> {
    const response = await this.uploadMedia(data, mimeType, fileName);
    return response.content_uri;
  }

  async downloadMedia(mxcUri: string): Promise<ArrayBuffer> {
    const parsed = MxcUtils.parseMxcUri(mxcUri);
    if (!parsed) {
      throw new Error('Invalid mxc:// URI');
    }
    try {
      const encodedPath = this.baseClient.encodePath(parsed.serverName, parsed.mediaId);
      const url = this.baseClient.buildMediaUrl(`/download/${encodedPath}`);
      return await this.baseClient.requestBinary(url);
    } catch (error) {
      this.logger.error('Failed to download media:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to download media: ${errMsg}`);
    }
  }

  async getThumbnail(
    mxcUri: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale',
    animated?: boolean
  ): Promise<ArrayBuffer> {
    const parsed = MxcUtils.parseMxcUri(mxcUri);
    if (!parsed) {
      throw new Error('Invalid mxc:// URI');
    }
    try {
      const encodedPath = this.baseClient.encodePath(parsed.serverName, parsed.mediaId);
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
      const url = this.baseClient.buildMediaUrl(`/thumbnail/${encodedPath}`, queryParams);
      return await this.baseClient.requestBinary(url);
    } catch (error) {
      this.logger.error('Failed to get thumbnail:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thumbnail: ${errMsg}`);
    }
  }

  async getUrlPreview(url: string, ts?: number): Promise<UrlPreviewResponse> {
    try {
      const queryParams = this.baseClient.buildQueryParams({
        'url': url,
        'ts': ts
      });
      return await this.baseClient.requestMediaJson<UrlPreviewResponse>('/preview_url', queryParams);
    } catch (error) {
      this.logger.error('Failed to get URL preview:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get URL preview: ${errMsg}`);
    }
  }

  async getMediaConfig(): Promise<MediaConfigResponse> {
    try {
      return await this.baseClient.requestMediaJson<MediaConfigResponse>('/config');
    } catch (error) {
      this.logger.error('Failed to get media config:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get media config: ${errMsg}`);
    }
  }

  getHttpUrl(mxcUri: string): string {
    const homeserver = this.baseClient.getBaseUrl();
    return MxcUtils.getHttpUri(mxcUri, homeserver);
  }

  getThumbnailUrl(
    mxcUri: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale'
  ): string {
    const homeserver = this.baseClient.getBaseUrl();
    return MxcUtils.getThumbnailHttpUri(mxcUri, homeserver, width, height, method);
  }

  parseMxcUri(mxcUri: string): ParsedMxcUri | null {
    return MxcUtils.parseMxcUri(mxcUri);
  }

  isMxcUri(uri: string): boolean {
    return MxcUtils.isMxcUri(uri);
  }
}
