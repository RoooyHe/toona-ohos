export interface MediaUploadResponse {
  content_uri: string;
}

export interface MediaConfig {
  'm.upload.size'?: number;
  'm.upload.size.total'?: number;
  'm.upload.size.room'?: number;
  'm.upload.size.session'?: number;
}

export interface UrlPreviewResponse {
  'og:title'?: string;
  'og:description'?: string;
  'og:image'?: string;
  'og:image:type'?: string;
  'og:image:width'?: number;
  'og:image:height'?: number;
  'og:image:size'?: number;
  'og:video'?: string;
  'og:video:type'?: string;
  'og:video:width'?: number;
  'og:video:height'?: number;
  'og:url'?: string;
  'og:type'?: string;
  'matrix:image:size'?: number;
  'matrix:mxc_to_http'?: string;
  'twitter:card'?: string;
  'twitter:image'?: string;
}

export interface ThumbnailQueryParams {
  width: number;
  height: number;
  method?: 'crop' | 'scale';
  animated?: boolean;
}