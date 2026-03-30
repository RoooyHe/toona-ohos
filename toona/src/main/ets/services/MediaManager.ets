import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { MediaUploadResponse, MediaConfig as MediaConfigResponse, UrlPreviewResponse } from '../models/MatrixTypes';
import { MxcUtils } from '../utils/MxcUtils';

interface GeneratedTypeLiteralInterface_1 {
  serverName: string;
  mediaId: string;
}

export class MediaManager {
  private static instance: MediaManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): MediaManager {
    if (!MediaManager.instance) {
      MediaManager.instance = new MediaManager();
    }
    return MediaManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      this.httpClient = MatrixConfig.getInstance().getHttpClient();
    }
    return this.httpClient;
  }

  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ): Promise<MediaUploadResponse> {
    try {
      return await this.ensureHttpClient().uploadMedia(data, contentType, fileName);
    } catch (error) {
      console.error('Failed to upload media:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to upload media: ${errMsg}`);
    }
  }

  async uploadImage(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'image/jpeg', fileName);
    return response.content_uri;
  }

  async uploadAudio(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'audio/mpeg', fileName);
    return response.content_uri;
  }

  async uploadVideo(data: ArrayBuffer, fileName: string): Promise<string> {
    const response = await this.uploadMedia(data, 'video/mp4', fileName);
    return response.content_uri;
  }

  async uploadFile(data: ArrayBuffer, fileName: string, mimeType: string = 'application/octet-stream'): Promise<string> {
    const response = await this.uploadMedia(data, mimeType, fileName);
    return response.content_uri;
  }

  async downloadMedia(mxcUri: string): Promise<ArrayBuffer> {
    const parsed = MxcUtils.parseMxcUri(mxcUri);
    if (!parsed) {
      throw new Error('Invalid mxc:// URI');
    }
    try {
      return await this.ensureHttpClient().downloadMedia(parsed.serverName, parsed.mediaId);
    } catch (error) {
      console.error('Failed to download media:', error);
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
      return await this.ensureHttpClient().getThumbnail(
        parsed.serverName,
        parsed.mediaId,
        width,
        height,
        method,
        animated
      );
    } catch (error) {
      console.error('Failed to get thumbnail:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get thumbnail: ${errMsg}`);
    }
  }

  async getUrlPreview(url: string, ts?: number): Promise<UrlPreviewResponse> {
    try {
      return await this.ensureHttpClient().getUrlPreview(url, ts);
    } catch (error) {
      console.error('Failed to get URL preview:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get URL preview: ${errMsg}`);
    }
  }

  async getMediaConfig(): Promise<MediaConfigResponse> {
    try {
      return await this.ensureHttpClient().getMediaConfig();
    } catch (error) {
      console.error('Failed to get media config:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get media config: ${errMsg}`);
    }
  }

  getHttpUrl(mxcUri: string): string {
    const homeserver = MatrixConfig.getInstance().getHomeserver();
    return MxcUtils.getHttpUri(mxcUri, homeserver);
  }

  getThumbnailUrl(
    mxcUri: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale'
  ): string {
    const homeserver = MatrixConfig.getInstance().getHomeserver();
    return MxcUtils.getThumbnailHttpUri(mxcUri, homeserver, width, height, method);
  }

  parseMxcUri(mxcUri: string): GeneratedTypeLiteralInterface_1 | null {
    return MxcUtils.parseMxcUri(mxcUri);
  }

  isMxcUri(uri: string): boolean {
    return MxcUtils.isMxcUri(uri);
  }
}