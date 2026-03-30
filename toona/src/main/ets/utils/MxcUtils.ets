export interface ParsedMxcUri {
  serverName: string;
  mediaId: string;
}

export class MxcUtils {
  static parseMxcUri(mxcUri: string): ParsedMxcUri | null {
    if (!mxcUri || !mxcUri.startsWith('mxc://')) {
      return null;
    }
    const withoutPrefix = mxcUri.substring(6);
    const slashIndex = withoutPrefix.indexOf('/');
    if (slashIndex <= 0 || slashIndex === withoutPrefix.length - 1) {
      return null;
    }
    const serverName = withoutPrefix.substring(0, slashIndex);
    const mediaId = withoutPrefix.substring(slashIndex + 1);
    if (!serverName || !mediaId) {
      return null;
    }
    return {
      serverName: serverName,
      mediaId: mediaId
    };
  }

  static buildMxcUri(serverName: string, mediaId: string): string {
    return `mxc://${serverName}/${mediaId}`;
  }

  static isMxcUri(uri: string): boolean {
    return !!uri && uri.startsWith('mxc://');
  }

  static getHttpUri(mxcUri: string, homeserverUrl: string): string {
    const parsed = this.parseMxcUri(mxcUri);
    if (!parsed) {
      return '';
    }
    let baseUrl = homeserverUrl.replace(/\/$/, '');
    return `${baseUrl}/_matrix/media/v3/download/${encodeURIComponent(parsed.serverName)}/${encodeURIComponent(parsed.mediaId)}`;
  }

  static getThumbnailHttpUri(
    mxcUri: string,
    homeserverUrl: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale'
  ): string {
    const parsed = this.parseMxcUri(mxcUri);
    if (!parsed) {
      return '';
    }
    let baseUrl = homeserverUrl.replace(/\/$/, '');
    let url = `${baseUrl}/_matrix/media/v3/thumbnail/${encodeURIComponent(parsed.serverName)}/${encodeURIComponent(parsed.mediaId)}?width=${width}&height=${height}`;
    if (method) {
      url += `&method=${method}`;
    }
    return url;
  }
}