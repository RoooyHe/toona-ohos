export class ConnectionConfig {
  private homeserverUrl: string = '';
  private accessToken: string | null = null;
  private connectTimeout: number = 30000;
  private readTimeout: number = 60000;

  getHomeserver(): string {
    return this.homeserverUrl;
  }

  setHomeserver(url: string): void {
    this.homeserverUrl = url;
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  setAccessToken(token: string | null): void {
    this.accessToken = token;
  }

  getConnectTimeout(): number {
    return this.connectTimeout;
  }

  setConnectTimeout(timeout: number): void {
    this.connectTimeout = timeout;
  }

  getReadTimeout(): number {
    return this.readTimeout;
  }

  setReadTimeout(timeout: number): void {
    this.readTimeout = timeout;
  }

  clear(): void {
    this.homeserverUrl = '';
    this.accessToken = null;
  }
}
