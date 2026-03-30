import { WellKnownInfo } from "../MatrixTypes";

export interface LoginIdentifier {
  type: string;
  user?: string;
  medium?: string;
  address?: string;
}

export interface LoginRequest {
  identifier: LoginIdentifier;
  password: string;
  device_id?: string;
  initial_device_display_name?: string;
}

export interface LoginResponse {
  user_id: string;
  access_token: string;
  home_server: string;
  device_id: string;
  well_known?: WellKnownInfo;
}

export interface AuthSession {
  session?: string;
  flows?: AuthenticationFlow[];
}

export interface RegisterRequest {
  username: string;
  password: string;
  device_id?: string;
  initial_device_display_name?: string;
  auth?: AuthSession;
}

export interface RegisterResponse {
  user_id: string;
  access_token: string;
  device_id: string;
  home_server: string;
  session?: string;
}

export interface AuthenticationFlow {
  stages: string[];
}

export interface WhoAmIResponse {
  user_id: string;
  device_id: string;
  is_guest: boolean;
  successors: string[];
}

export interface ProfileInfo {
  displayname?: string;
  avatar_url?: string;
}