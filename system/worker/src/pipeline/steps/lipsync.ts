// worker/src/pipeline/steps/lipsync.ts
import { db } from "../../lib/firestore";
import {
    replicatePredictWaitByModelPath,
    extractReplicateVideoUrl,
    ReplicatePrediction,
} from "../../../../src/services/replicate";
import { cloudinaryUploadVideoFromUrl } from "../../../../src/services/cloudinary";

const LIPSYNC_MODEL_PATH = "sync/lipsync-2";

/**
 * Lipsync:
 *  - Input video: public faceswap MP4 (Replicate result URL)
 *  - Input audio: Cloudinary MP3 secure_url
 *  - Polls Replicate until terminal
 *  - Uploads lipsynced result to Cloudinary and returns its URL
 */
export async function runLipsync(
    jobId: string,
    faceswapPublicUrl: string,
    audioUrl: string
): Promise<string> {
    if (!/^https?:\/\//.test(faceswapPublicUrl)) throw new Error("invalid_faceswap_public_url");
    if (!/^https?:\/\//.test(audioUrl)) throw new Error("invalid_audio_url");

    await db.collection("jobs").doc(jobId).update({
        status: "lipsync",
        updated_at: Date.now(),
    });

    const pred: ReplicatePrediction = await replicatePredictWaitByModelPath(LIPSYNC_MODEL_PATH, {
        audio: audioUrl,
        video: faceswapPublicUrl,
        sync_mode: "silence",
        temperature: 0.5,
        active_speaker: false,
    });

    if (pred.status !== "succeeded") {
        await db.collection("jobs").doc(jobId).update({
            "vendor_refs.replicate": { id: pred.id, web: pred.urls?.web, get: pred.urls?.get },
            updated_at: Date.now(),
        });
        throw new Error(`replicate_status_${pred.status}`);
    }

    const resultUrl = extractReplicateVideoUrl(pred.output);
    if (!resultUrl) {
        await db.collection("jobs").doc(jobId).update({
            "vendor_refs.replicate": { id: pred.id, web: pred.urls?.web, get: pred.urls?.get },
            updated_at: Date.now(),
        });
        throw new Error("replicate_empty_output");
    }

    const up = await cloudinaryUploadVideoFromUrl(resultUrl, `leadrole-lipsync-${jobId}`);

    await db.collection("jobs").doc(jobId).update({
        "assets.lipsync_url": up.secure_url,
        "assets.lipsync_public_id": up.public_id,
        updated_at: Date.now(),
    });

    return up.secure_url;
}