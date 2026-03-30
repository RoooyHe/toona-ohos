export interface ThirdpartyProtocol {
  name: string;
  description?: string;
  icon?: string;
  fields: Record<string, string | object>;
}

export interface ThirdpartyProtocolsResponse {
  protocols: Record<string, ThirdpartyProtocol>;
}

export interface ThirdpartyUser {
  user_id?: string;
  medium?: string;
  address?: string;
}

export interface ThirdpartyLocation {
  alias: string;
  fields?: Record<string, string>;
}

export interface ThirdpartyUserResponse {
  users: ThirdpartyUser[];
}

export interface ThirdpartyLocationResponse {
  locations: ThirdpartyLocation[];
}