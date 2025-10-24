export interface PutResult {
    url: string;
    id?: string;
}

export interface StorageAdapter {
    putVideo(buffer: Buffer, key: string, contentType?: string): Promise<PutResult>;
}