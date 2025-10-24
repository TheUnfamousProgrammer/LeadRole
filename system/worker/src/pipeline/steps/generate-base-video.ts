import { db } from "../../lib/firestore";
import { lumaGenerate, lumaGetStatus } from "../../../../src/services/luma";

export async function generateBase(jobId: string, prompt: string, aspect_ratio: string, duration: string, startWith?: {
    luma_id?: string; base_video_url?: string;
}) {
    // If we’re resuming and already have URL, just return
    if (startWith?.base_video_url) {
        return { lumaId: startWith.luma_id || null, videoUrl: startWith.base_video_url };
    }

    await db.collection("jobs").doc(jobId).update({
        status: "generating_base_video",
        updated_at: Date.now(),
    });

    let lumaId = startWith?.luma_id;
    if (!lumaId) {
        const gen = await lumaGenerate(prompt, aspect_ratio, duration);
        lumaId = gen.id as string;
    }

    await db.collection("jobs").doc(jobId).update({
        "vendor_refs.luma_id": lumaId,
        updated_at: Date.now(),
    });

    const maxWaitMs = Number(process.env.MAX_LUMA_WAIT_MS || 480000);
    const pollInterval = Number(process.env.LUMA_POLL_INTERVAL || 5000);
    const start = Date.now();

    let videoUrl: string | undefined;
    let lastProgressUrl: string | undefined;
    let lastThumb: string | undefined;

    const tapProgress = async (s: any) => {
        const pv = s?.assets?.progress_video;
        const img = s?.assets?.image;
        const changed = (pv && pv !== lastProgressUrl) || (img && img !== lastThumb);
        if (changed) {
            lastProgressUrl = pv || lastProgressUrl;
            lastThumb = img || lastThumb;
            await db.collection("jobs").doc(jobId).update({
                "assets.progress_video_url": lastProgressUrl || null,
                "assets.progress_thumb_url": lastThumb || null,
                updated_at: Date.now(),
            });
        }
    };

    const tryGet = async () => {
        const s = await lumaGetStatus(lumaId!);
        await tapProgress(s);
        if (s.state === "failed") throw new Error("luma_failed");
        if (s.state === "completed" && s.assets?.video) return s.assets.video as string;
        return undefined;
    };

    while (Date.now() - start < maxWaitMs) {
        videoUrl = await tryGet();
        if (videoUrl) break;
        await new Promise(r => setTimeout(r, pollInterval));
    }

    if (!videoUrl) {
        // grace probe
        videoUrl = await tryGet();
    }

    if (!videoUrl) {
        await db.collection("jobs").doc(jobId).update({
            error: { message: "luma_timeout", waited_ms: Date.now() - start },
            updated_at: Date.now(),
        });
        throw new Error("luma_timeout");
    }

    return { lumaId, videoUrl };
}