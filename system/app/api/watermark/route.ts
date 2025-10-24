import { NextRequest, NextResponse } from "next/server";
import { burnWatermarkToBuffer } from "../../../worker/src/pipeline/steps/watermark";
import { storage } from "../../../src/services/storage";

export async function POST(req: NextRequest) {
    try {
        const { video_url, watermark_url } = await req.json();
        if (!video_url) {
            return NextResponse.json({ error: "missing_video_url" }, { status: 400 });
        }

        const watermark =
            watermark_url ||
            "https://imagedelivery.net/nIXg1hqSCosmvn2DEPXE5A/3e06fb0a-0862-490e-4632-0c2c5390f200/public";

        const buf = await burnWatermarkToBuffer(null, video_url, watermark);

        const key = `leadrole-watermark-test-${Date.now()}`;
        const res = await storage.putVideo(buf, key, "video/mp4");

        return NextResponse.json({
            status: "success",
            source: video_url,
            watermark,
            watermarked_url: res.url,
            id: res.id ?? key,
        });
    } catch (err: any) {
        console.error("watermark failed", err);
        return NextResponse.json({ error: err.message ?? "internal_error" }, { status: 500 });
    }
}

export const runtime = "nodejs";
export const dynamic = "force-dynamic";