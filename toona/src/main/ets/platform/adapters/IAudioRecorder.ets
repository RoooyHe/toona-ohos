export interface RecordingResult {
  buffer: ArrayBuffer;
  fileName: string;
}

export interface IAudioRecorder {
  requestPermission(context: Object): Promise<boolean>;
  start(context: Object): Promise<Object | null>;
  stop(recorder: Object, audioPath: string, audioFd: number): Promise<RecordingResult | null>;
}
