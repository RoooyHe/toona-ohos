import { BaseHttpClient } from './clients/BaseHttpClient';
import { MediaHttpClient } from './clients/MediaHttpClient';
import { RoomHttpClient } from './clients/RoomHttpClient';
import { MessageHttpClient } from './clients/MessageHttpClient';
import { UserHttpClient } from './clients/UserHttpClient';
import { DeviceAuthData, DeviceHttpClient } from './clients/DeviceHttpClient';
import { FilterHttpClient } from './clients/FilterHttpClient';
import { PresenceHttpClient } from './clients/PresenceHttpClient';
import { ThirdpartyHttpClient } from './clients/ThirdpartyHttpClient';
import { OpenIdHttpClient } from './clients/OpenIdHttpClient';
import { VoipHttpClient } from './clients/VoipHttpClient';
import { HttpVersion } from './clients/BaseHttpClient';
import {
  PushRuleAction,
  RoomAvatarContent,
  SetPresenceRequest,
  QueryKeysRequest,
  UploadKeysRequest,
  ClaimKeysRequest,
  QueryRoomKeysRequest,
  UploadRoomKeysRequest,
  UploadRoomKeysRoomsData,
  KeyBackupSessionData,
  SignatureRequest,
  Filter,
  UpdateDeviceRequest,
  OpenIdRequest,
  PushRule,
  SetNotificationMarkerRequest,
  SetReadMarkersRequest,
  PublicRoom
} from '../models/MatrixTypes';

export class MatrixHttpClient {
  private baseClient: BaseHttpClient;
  private mediaClient: MediaHttpClient;
  private roomClient: RoomHttpClient;
  private messageClient: MessageHttpClient;
  private userClient: UserHttpClient;
  private deviceClient: DeviceHttpClient;
  private filterClient: FilterHttpClient;
  private presenceClient: PresenceHttpClient;
  private thirdpartyClient: ThirdpartyHttpClient;
  private openIdClient: OpenIdHttpClient;
  private voipClient: VoipHttpClient;

  constructor(baseUrl: string) {
    this.baseClient = new BaseHttpClient(baseUrl);
    this.mediaClient = new MediaHttpClient(baseUrl);
    this.roomClient = new RoomHttpClient(baseUrl);
    this.messageClient = new MessageHttpClient(baseUrl);
    this.userClient = new UserHttpClient(baseUrl);
    this.deviceClient = new DeviceHttpClient(baseUrl);
    this.filterClient = new FilterHttpClient(baseUrl);
    this.presenceClient = new PresenceHttpClient(baseUrl);
    this.thirdpartyClient = new ThirdpartyHttpClient(baseUrl);
    this.openIdClient = new OpenIdHttpClient(baseUrl);
    this.voipClient = new VoipHttpClient(baseUrl);
  }

  setAccessToken(token: string | null): void {
    this.baseClient.setAccessToken(token);
    this.mediaClient.setAccessToken(token);
    this.roomClient.setAccessToken(token);
    this.messageClient.setAccessToken(token);
    this.userClient.setAccessToken(token);
    this.deviceClient.setAccessToken(token);
    this.filterClient.setAccessToken(token);
    this.presenceClient.setAccessToken(token);
    this.thirdpartyClient.setAccessToken(token);
    this.openIdClient.setAccessToken(token);
    this.voipClient.setAccessToken(token);
  }

  getAccessToken(): string | null {
    return this.baseClient.getAccessToken();
  }

  public buildMediaUrl(endpoint: string, queryParams?: Record<string, string | number>): string {
    return this.baseClient.buildMediaUrl(endpoint, queryParams);
  }

  public buildUrl(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): string {
    return this.baseClient.buildUrl(endpoint, queryParams, version);
  }

  public buildHeaders(): Record<string, string> {
    return this.baseClient.buildHeaders();
  }

  async request<T>(
    method: string,
    endpoint: string,
    body?: Record<string, string | object>,
    queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'
  ): Promise<T> {
    return this.baseClient.request<T>(method, endpoint, body, queryParams, version);
  }

  async get<T>(endpoint: string, queryParams?: Record<string, string | number>,
    version: HttpVersion = 'v3'): Promise<T> {
    return this.baseClient.get<T>(endpoint, queryParams, version);
  }

  async getWithoutVersionPrefix<T>(endpoint: string): Promise<T> {
    return this.baseClient.getWithoutVersionPrefix<T>(endpoint);
  }

  async post<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.baseClient.post<T>(endpoint, body);
  }

  async put<T>(endpoint: string, body?: Record<string, string | object>): Promise<T> {
    return this.baseClient.put<T>(endpoint, body);
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.baseClient.delete<T>(endpoint);
  }

  async upload<T>(
    endpoint: string,
    data: ArrayBuffer,
    contentType: string,
    fileName: string
  ): Promise<T> {
    return this.baseClient.upload<T>(endpoint, data, contentType, fileName);
  }

  async uploadMedia(
    data: ArrayBuffer,
    contentType: string,
    fileName?: string
  ) {
    return this.mediaClient.uploadMedia(data, contentType, fileName);
  }

  async downloadMedia(serverName: string, mediaId: string): Promise<ArrayBuffer> {
    return this.mediaClient.downloadMedia(serverName, mediaId);
  }

  async getThumbnail(
    serverName: string,
    mediaId: string,
    width: number,
    height: number,
    method?: 'crop' | 'scale',
    animated?: boolean
  ): Promise<ArrayBuffer> {
    return this.mediaClient.getThumbnail(serverName, mediaId, width, height, method, animated);
  }

  async getUrlPreview(url: string, ts?: number) {
    return this.mediaClient.getUrlPreview(url, ts);
  }

  async getMediaConfig() {
    return this.mediaClient.getMediaConfig();
  }

  async setRoomAvatar(roomId: string, avatar: RoomAvatarContent): Promise<void> {
    return this.roomClient.setRoomAvatar(roomId, avatar);
  }

  async getCanonicalAlias(roomId: string) {
    return this.roomClient.getCanonicalAlias(roomId);
  }

  async setCanonicalAlias(roomId: string, alias: string): Promise<void> {
    return this.roomClient.setCanonicalAlias(roomId, alias);
  }

  async getRoomAliases(roomId: string) {
    return this.roomClient.getRoomAliases(roomId);
  }

  async setRoomAliases(roomId: string, aliases: string[]): Promise<void> {
    return this.roomClient.setRoomAliases(roomId, aliases);
  }

  async getRoomMembers(roomId: string, start?: string, end?: string, sess?: string) {
    return this.roomClient.getRoomMembers(roomId, start, end, sess);
  }

  async setReadMarkers(roomId: string, request: SetReadMarkersRequest): Promise<void> {
    return this.roomClient.setReadMarkers(roomId, request);
  }

  async getReceipt(roomId: string, receiptType: string, eventId: string) {
    return this.roomClient.getReceipt(roomId, receiptType, eventId);
  }

  async postReceipt(roomId: string, receiptType: string, eventId: string, threadId?: string): Promise<void> {
    return this.roomClient.postReceipt(roomId, receiptType, eventId, threadId);
  }

  async createRoomAlias(roomAlias: string, roomId: string, servers: string[]): Promise<void> {
    return this.roomClient.createRoomAlias(roomAlias, roomId, servers);
  }

  async deleteRoomAlias(roomAlias: string): Promise<void> {
    return this.roomClient.deleteRoomAlias(roomAlias);
  }

  async resolveRoomAlias(roomAlias: string) {
    return this.roomClient.resolveRoomAlias(roomAlias);
  }

  async getPublicRooms(server?: string, limit?: number, since?: string) {
    return this.roomClient.getPublicRooms(server, limit, since);
  }

  async postPublicRooms(room: Partial<PublicRoom>) {
    return this.roomClient.postPublicRooms(room);
  }

  async putTyping(roomId: string, userId: string, typing: boolean, timeout?: number): Promise<void> {
    return this.messageClient.putTyping(roomId, userId, typing, timeout);
  }

  async getTypingUsers(roomId: string, userId: string): Promise<string[]> {
    return this.messageClient.getTypingUsers(roomId, userId);
  }

  async getRelations(
    roomId: string,
    eventId: string,
    relType?: string,
    eventType?: string,
    limit?: number,
    direction?: 'f' | 'b'
  ) {
    return this.messageClient.getRelations(roomId, eventId, relType, eventType, limit, direction);
  }

  async addAnnotation(
    roomId: string,
    eventId: string,
    relType: string,
    key: string,
    type: string,
    content: Record<string, string | object>
  ): Promise<void> {
    return this.messageClient.addAnnotation(roomId, eventId, relType, key, type, content);
  }

  async getDisplayName(userId: string): Promise<string | null> {
    return this.userClient.getDisplayName(userId);
  }

  async setDisplayName(userId: string, displayName: string): Promise<void> {
    return this.userClient.setDisplayName(userId, displayName);
  }

  async getAvatarUrl(userId: string): Promise<string | null> {
    return this.userClient.getAvatarUrl(userId);
  }

  async setAvatarUrl(userId: string, avatarUrl: string): Promise<void> {
    return this.userClient.setAvatarUrl(userId, avatarUrl);
  }

  async getPushRules() {
    return this.userClient.getPushRules();
  }

  async getPushRule(scope: string, kind: string, ruleId: string) {
    return this.userClient.getPushRule(scope, kind, ruleId);
  }

  async setPushRule(
    scope: string,
    kind: string,
    ruleId: string,
    rule: Partial<PushRule>
  ): Promise<void> {
    return this.userClient.setPushRule(scope, kind, ruleId, rule);
  }

  async deletePushRule(scope: string, kind: string, ruleId: string): Promise<void> {
    return this.userClient.deletePushRule(scope, kind, ruleId);
  }

  async setPushRuleActions(
    scope: string,
    kind: string,
    ruleId: string,
    actions: PushRuleAction[]
  ): Promise<void> {
    return this.userClient.setPushRuleActions(scope, kind, ruleId, actions);
  }

  async getNotifications(limit?: number, since?: string, only?: string) {
    return this.userClient.getNotifications(limit, since, only);
  }

  async setNotificationMarker(request: SetNotificationMarkerRequest): Promise<void> {
    return this.userClient.setNotificationMarker(request);
  }

  async getRoomTags(userId: string, roomId: string) {
    return this.userClient.getRoomTags(userId, roomId);
  }

  async addRoomTag(
    userId: string,
    roomId: string,
    tag: string,
    order?: number
  ): Promise<void> {
    return this.userClient.addRoomTag(userId, roomId, tag, order);
  }

  async removeRoomTag(userId: string, roomId: string, tag: string): Promise<void> {
    return this.userClient.removeRoomTag(userId, roomId, tag);
  }

  async getDevices() {
    return this.deviceClient.getDevices();
  }

  async getDevice(deviceId: string) {
    return this.deviceClient.getDevice(deviceId);
  }

  async updateDevice(deviceId: string, update: UpdateDeviceRequest): Promise<void> {
    return this.deviceClient.updateDevice(deviceId, update);
  }

  // 2. 找到原来的 deleteDevice，增加 authData 参数
  deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    return this.deviceClient.deleteDevice(deviceId, authData);
  }

  // 3. 补充上批量删除的透传方法（如果您需要用到的话）
  deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    return this.deviceClient.deleteDevices(deviceIds, authData);
  }

  // ✅ 加上 : Promise<Record<string, Object>> 即可
  queryKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.queryKeys(request);
  }

  uploadKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.uploadKeys(request);
  }

  claimKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.claimKeys(request);
  }

  queryRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.queryRoomKeys(request);
  }

  uploadRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.uploadRoomKeys(request);
  }

  getRoomKeys(version?: string): Promise<Record<string, Object>> {
    return this.deviceClient.getRoomKeys(version);
  }

  putRoomKeys(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.putRoomKeys(version, request);
  }

  async getKeyBackupVersion() {
    return this.deviceClient.getKeyBackupVersion();
  }

  putKeyBackupVersion(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.putKeyBackupVersion(version, request);
  }

  createKeyBackupVersion(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.createKeyBackupVersion(request);
  }

  deleteKeyBackupVersion(version: string): Promise<Record<string, Object>> {
    return this.deviceClient.deleteKeyBackupVersion(version);
  }

  uploadSignatures(request: Record<string, Object>): Promise<Record<string, Object>> {
    return this.deviceClient.uploadSignatures(request);
  }

  async createFilter(userId: string, filter: Filter, version?: HttpVersion) {
    return this.filterClient.createFilter(userId, filter, version);
  }

  async getFilter(userId: string, filterId: string, version?: HttpVersion) {
    return this.filterClient.getFilter(userId, filterId, version);
  }

  async getPresence(userId: string) {
    return this.presenceClient.getPresence(userId);
  }

  async setPresence(userId: string, request: SetPresenceRequest): Promise<void> {
    return this.presenceClient.setPresence(userId, request);
  }

  async getPresenceList(userIds: string[]) {
    return this.presenceClient.getPresenceList(userIds);
  }

  async getThirdpartyProtocols() {
    return this.thirdpartyClient.getThirdpartyProtocols();
  }

  async getThirdpartyProtocol(protocol: string) {
    return this.thirdpartyClient.getThirdpartyProtocol(protocol);
  }

  async thirdpartyUserSearch(
    protocol: string,
    params: Record<string, string | string[]>
  ) {
    return this.thirdpartyClient.thirdpartyUserSearch(protocol, params);
  }

  async thirdpartyUserDiscovery(params: Record<string, string | string[]>) {
    return this.thirdpartyClient.thirdpartyUserDiscovery(params);
  }

  async thirdpartyLocationSearch(
    protocol: string,
    params: Record<string, string | string[]>
  ) {
    return this.thirdpartyClient.thirdpartyLocationSearch(protocol, params);
  }

  async thirdpartyLocationDiscovery(params: Record<string, string | string[]>) {
    return this.thirdpartyClient.thirdpartyLocationDiscovery(params);
  }

  async requestOpenIdToken(userId: string, request: OpenIdRequest | undefined) {
    return this.openIdClient.requestOpenIdToken(userId, request);
  }

  async getVoipTurnServer() {
    return this.voipClient.getVoipTurnServer();
  }
}

export class MatrixConfig {
  private static instance: MatrixConfig;
  private homeserverUrl: string = '';
  private _httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): MatrixConfig {
    if (!MatrixConfig.instance) {
      MatrixConfig.instance = new MatrixConfig();
    }
    return MatrixConfig.instance;
  }

  setHomeserver(url: string): void {
    this.homeserverUrl = url;
    this._httpClient = new MatrixHttpClient(url);
  }

  getHomeserver(): string {
    return this.homeserverUrl;
  }

  getHttpClient(): MatrixHttpClient {
    if (!this._httpClient) {
      throw new Error('MatrixConfig not initialized. Call setHomeserver first.');
    }
    return this._httpClient;
  }

  clear(): void {
    this.homeserverUrl = '';
    this._httpClient = null;
  }
}

export function createMatrixClient(homeserverUrl: string): MatrixHttpClient {
  MatrixConfig.getInstance().setHomeserver(homeserverUrl);
  return MatrixConfig.getInstance().getHttpClient();
}
