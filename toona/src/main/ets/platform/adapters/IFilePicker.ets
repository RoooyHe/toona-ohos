export interface SelectedFile {
  uri: string;
  buffer: ArrayBuffer;
  fileName: string;
  fileSize: number;
}

export interface IFilePicker {
  selectImage(): Promise<SelectedFile | null>;
  selectMultipleImages(maxCount: number): Promise<SelectedFile[]>;
  readFileBuffer(uri: string): Promise<ArrayBuffer | null>;
}
