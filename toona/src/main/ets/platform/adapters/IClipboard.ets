export interface IClipboard {
  copyText(text: string): Promise<void>;
}
