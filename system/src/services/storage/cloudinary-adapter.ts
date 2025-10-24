import { StorageAdapter, PutResult } from "./types";

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME!;
const UPLOAD_PRESET = process.env.CLOUDINARY_UPLOAD_PRESET!;
const BASE_URL = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}`;

function toDataURI(buffer: Buffer, contentType = "video/mp4") {
    const b64 = buffer.toString("base64");
    return `data:${contentType};base64,${b64}`;
}

export const cloudinaryAdapter: StorageAdapter = {
    async putVideo(buffer: Buffer, key: string, contentType = "video/mp4"): Promise<PutResult> {
        if (!CLOUD_NAME) throw new Error("missing CLOUDINARY_CLOUD_NAME");
        if (!UPLOAD_PRESET) throw new Error("missing CLOUDINARY_UPLOAD_PRESET");

        const form = new FormData();
        form.append("file", toDataURI(buffer, contentType)); // << no Blob needed
        form.append("upload_preset", UPLOAD_PRESET);
        form.append("public_id", key);

        const res = await fetch(`${BASE_URL}/video/upload`, { method: "POST", body: form });
        if (!res.ok) {
            const t = await res.text().catch(() => "");
            throw new Error(`cloudinary_upload_${res.status}_${t}`);
        }
        const json: any = await res.json();
        return { url: json.secure_url, id: json.public_id };
    },
};