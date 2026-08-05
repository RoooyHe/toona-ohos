export class ConnectionConfig {
  private homeserverUrl: string = '';
  private accessToken: string | null = null;

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

  clear(): void {
    this.homeserverUrl = '';
    this.accessToken = null;
  }
}
