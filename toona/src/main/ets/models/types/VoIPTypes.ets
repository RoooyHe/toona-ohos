export interface VoipTurnServerResponse {
  uris: string[];
  username?: string;
  credential?: string;
  ttl?: number;
}

export interface OpenIdRequest {
  nonce?: string;
}

export interface OpenIdResponse {
  token_type: string;
  access_token: string;
  expires_in: number;
  matrix_server_name: string;
}