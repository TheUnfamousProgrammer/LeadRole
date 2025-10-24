
import { createHash } from "crypto";

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME!;
const UPLOAD_PRESET = process.env.CLOUDINARY_UPLOAD_PRESET; // unsigned preset for MVP

if (!CLOUD_NAME) throw new Error("missing CLOUDINARY_CLOUD_NAME");
if (!UPLOAD_PRESET) throw new Error("missing CLOUDINARY_UPLOAD_PRESET (create an unsigned preset)");

const API_KEY = process.env.CLOUDINARY_API_KEY!;
const API_SECRET = process.env.CLOUDINARY_API_SECRET!;

if (!CLOUD_NAME) throw new Error("missing CLOUDINARY_CLOUD_NAME");
if (!API_KEY || !API_SECRET) {
    console.warn("Cloudinary: missing API key/secret — signed uploads will fail.");
}


const baseUrl = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}`;

export type CloudinaryUploadResult = {
    asset_id: string;
    public_id: string;
    secure_url: string;
    resource_type: "image" | "video" | "raw" | "auto";
};

export async function cloudinaryUploadMp3(buffer: Buffer, publicId?: string): Promise<CloudinaryUploadResult> {
    const form = new FormData();
    form.append("file", new Blob([new Uint8Array(buffer)]), `${publicId ?? "audio"}.mp3`);
    form.append("upload_preset", UPLOAD_PRESET!);
    if (publicId) form.append("public_id", publicId);

    const r = await fetch(`${baseUrl}/auto/upload`, { method: "POST", body: form });
    if (!r.ok) throw new Error(`cloudinary_mp3_${r.status}_${await r.text().catch(() => "")}`);
    return (await r.json()) as CloudinaryUploadResult;
}

export async function cloudinaryUploadVideoFromUrl(url: string, publicId?: string): Promise<CloudinaryUploadResult> {
    const form = new FormData();
    form.append("file", url);
    form.append("upload_preset", UPLOAD_PRESET!);
    if (publicId) form.append("public_id", publicId);

    const r = await fetch(`${baseUrl}/video/upload`, { method: "POST", body: form });
    if (!r.ok) throw new Error(`cloudinary_video_url_${r.status}_${await r.text().catch(() => "")}`);
    return (await r.json()) as CloudinaryUploadResult;
}

function b64url(input: string) {
    return Buffer.from(input).toString("base64").replace(/\+/g, "-").replace(/\//g, "_");
}

export async function cloudinaryUploadVideoWithOverlayFromUrl(
    inputVideoUrl: string,
    watermarkUrl: string,
    publicId?: string
): Promise<CloudinaryUploadResult> {
    const overlay = `l_fetch:${b64url(watermarkUrl)}/fl_relative,w_0.11,g_south_east,x_24,y_24`;

    const form = new FormData();
    form.append("file", inputVideoUrl);             // Cloudinary fetches the URL
    form.append("upload_preset", UPLOAD_PRESET!);
    form.append("transformation", overlay);
    if (publicId) form.append("public_id", publicId);

    const r = await fetch(`${baseUrl}/video/upload`, { method: "POST", body: form });
    if (!r.ok) throw new Error(`cloudinary_video_overlay_${r.status}_${await r.text().catch(() => "")}`);
    return (await r.json()) as CloudinaryUploadResult;
}

export async function cloudinarySignedUploadVideoWithOverlayFromUrl(
    inputVideoUrl: string,
    watermarkUrl: string,
    publicId?: string
): Promise<{ asset_id: string; public_id: string; secure_url: string; resource_type: string }> {
    if (!API_KEY || !API_SECRET) throw new Error("missing Cloudinary API key/secret for signed upload");

    const transformation = `l_fetch:${b64url(watermarkUrl)}/fl_relative,w_0.11,g_south_east,x_24,y_24`;

    const timestamp = Math.floor(Date.now() / 1000).toString();
    const paramsToSign: Record<string, string> = {
        ...(publicId ? { public_id: publicId } : {}),
        timestamp,
        transformation,
    };

    const toSign = Object.keys(paramsToSign)
        .sort()
        .map((k) => `${k}=${paramsToSign[k]}`)
        .join("&");

    const signature = createHash("sha1").update(toSign + API_SECRET).digest("hex");

    const form = new FormData();
    form.append("file", inputVideoUrl);
    if (publicId) form.append("public_id", publicId);
    form.append("timestamp", timestamp);
    form.append("transformation", transformation);
    form.append("api_key", API_KEY);
    form.append("signature", signature);

    const res = await fetch(`${baseUrl}/video/upload`, { method: "POST", body: form });
    if (!res.ok) {
        const t = await res.text().catch(() => "");
        throw new Error(`cloudinary_signed_overlay_${res.status}_${t}`);
    }
    return (await res.json()) as any;
}

export async function cloudinaryExplicitEagerOverlayVideo(
    publicId: string,
    watermarkUrl: string
): Promise<string> {
    if (!CLOUD_NAME || !API_KEY || !API_SECRET) {
        throw new Error("Cloudinary signed upload requires CLOUDINARY_CLOUD_NAME/API_KEY/API_SECRET");
    }

    const overlay = `l_fetch:${b64url(watermarkUrl)}/fl_relative,w_0.11,g_south_east,x_24,y_24`;

    const endpoint = `${baseUrl}/video/explicit`;
    const timestamp = Math.floor(Date.now() / 1000).toString();

    const toSignObj: Record<string, string> = {
        eager: overlay,
        public_id: publicId,
        timestamp,
        type: "upload",
    };
    const toSign = Object.keys(toSignObj)
        .sort()
        .map((k) => `${k}=${toSignObj[k]}`)
        .join("&");
    const signature = createHash("sha1").update(toSign + API_SECRET).digest("hex");

    const form = new FormData();
    form.append("public_id", publicId);
    form.append("type", "upload");
    form.append("eager", overlay);
    form.append("timestamp", timestamp);
    form.append("api_key", API_KEY);
    form.append("signature", signature);

    const res = await fetch(endpoint, { method: "POST", body: form });
    if (!res.ok) {
        const t = await res.text().catch(() => "");
        throw new Error(`cloudinary_explicit_eager_${res.status}_${t}`);
    }
    const json: any = await res.json();

    const eagerUrl: string | undefined =
        json?.eager?.[0]?.secure_url || json?.eager?.[0]?.url;

    if (eagerUrl) return eagerUrl;

    const deliveryUrl = `https://res.cloudinary.com/${CLOUD_NAME}/video/upload/${overlay}/${publicId}.mp4`;
    return deliveryUrl;
}