/**
 * E2EE (End-to-End Encryption) type definitions for Matrix Megolm/Olm
 */

export interface DeviceIdentity {
  userId: string;
  deviceId: string;
  ed25519Key: string;
  curve25519Key: string;
  algorithms: string[];
  signatures: Record<string, Record<string, string>>;
}

export interface InboundGroupSessionInfo {
  roomId: string;
  senderKey: string;
  sessionId: string;
  sessionKey: string;
  forwardingChain: string[];
  createdAt: number;
}

export interface OutboundGroupSessionInfo {
  roomId: string;
  sessionId: string;
  sessionKey: string;
  messageIndex: number;
}

export interface OlmSessionInfo {
  deviceKey: string;
  sessionId: string;
  sessionKey: string;
  lastUsed: number;
}

export interface RoomKeyEvent {
  type: string;
  algorithm: string;
  room_id: string;
  session_id: string;
  session_key: string;
  sender_key: string;
  sender_claimed_keys?: Record<string, string>;
  forwarding_curve25519_key_chain?: string[];
}

export interface EncryptedEventContent {
  algorithm: string;
  ciphertext: string;
  device_id: string;
  session_id: string;
  sender_key: string;
}

export interface DecryptedEvent {
  eventId: string;
  roomId: string;
  sender: string;
  type: string;
  content: Record<string, string | object>;
  timestamp: number;
  decryptionError?: string;
}

export interface ToDeviceEvent {
  type: string;
  sender: string;
  content: Record<string, string | object>;
  recipient?: string;
  recipient_device?: string;
}

export interface KeyUploadData {
  deviceKeys: DeviceIdentity;
  oneTimeKeys?: Record<string, string>;
  fallbackKeys?: Record<string, string>;
}

// Megolm algorithm constants
export const MEGOLM_ALGORITHM = 'm.megolm.v1.aes-sha2';
export const OLM_ALGORITHM = 'm.olm.v1.curve25519-aes-sha2';

// Key upload counts
export const ONE_TIME_KEY_TARGET = 50;
export const FALLBACK_KEY_COUNT = 1;

// ── Key Verification Types ──

/**
 * Trust level for a device
 */
export enum VerificationState {
  UNVERIFIED = 'unverified',
  VERIFIED = 'verified',
  BLOCKED = 'blocked'
}

/**
 * Verification method
 */
export enum VerificationMethod {
  SAS = 'm.sas.v1',
  QR_CODE_SHOW = 'm.qr_code.show.v1',
  QR_CODE_SCAN = 'm.qr_code.scan.v1'
}

/**
 * Verification phase
 */
export enum VerificationPhase {
  REQUEST = 'request',
  READY = 'ready',
  START = 'start',
  KEY = 'key',
  MAC = 'mac',
  DONE = 'done',
  CANCEL = 'cancel'
}

/**
 * Verification request event content
 */
export interface VerificationRequestEvent {
  from_device: string;
  methods: string[];
  timestamp: number;
  transaction_id: string;
}

/**
 * Verification ready event content
 */
export interface VerificationReadyEvent {
  methods: string[];
  transaction_id: string;
}

/**
 * Verification start event content
 */
export interface VerificationStartEvent {
  method: string;
  short_authentication_string: string[];
  transaction_id: string;
  key_agreement_protocols: string[];
  hashes: string[];
  authentication_codes: string[];
}

/**
 * Verification key event content
 */
export interface VerificationKeyEvent {
  key: string;
  transaction_id: string;
}

/**
 * Verification MAC event content
 */
export interface VerificationMacEvent {
  keys: string;
  mac: Record<string, string>;
  transaction_id: string;
}

/**
 * Verification cancel event content
 */
export interface VerificationCancelEvent {
  code: string;
  reason: string;
  transaction_id: string;
}

/**
 * Verification session state
 */
export interface VerificationSession {
  transactionId: string;
  userId: string;
  deviceId: string;
  method: VerificationMethod;
  phase: VerificationPhase;
  started: boolean;
  sasBytes?: number[];
  sasVerified?: boolean;
  createdAt: number;
  expiresAt: number;
}

/**
 * SAS (Short Authentication String) digits
 */
export interface SasDigits {
  decimal: string;
  emoji: string[];
}

// Verification event types
export const KEY_VERIFICATION_REQUEST = 'm.keyverification.request';
export const KEY_VERIFICATION_READY = 'm.keyverification.ready';
export const KEY_VERIFICATION_START = 'm.keyverification.start';
export const KEY_VERIFICATION_KEY = 'm.keyverification.key';
export const KEY_VERIFICATION_MAC = 'm.keyverification.mac';
export const KEY_VERIFICATION_CANCEL = 'm.keyverification.cancel';
export const KEY_VERIFICATION_DONE = 'm.keyverification.done';

// Verification timeout (5 minutes)
export const VERIFICATION_TIMEOUT_MS = 300000;
