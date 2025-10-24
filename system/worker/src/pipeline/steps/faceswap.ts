// worker/src/pipeline/steps/faceswap.ts
import { db } from "../../lib/firestore";
import {
    replicatePredictWaitByVersion,
    extractReplicateVideoUrl,
    ReplicatePrediction,
} from "../../../../src/services/replicate";
import { cloudinaryUploadVideoFromUrl } from "../../../../src/services/cloudinary";

const ROOP_VERSION =
    "okaris/roop:8c1e100ecabb3151cf1e6c62879b6de7a4b84602de464ed249b6cff0b86211d8";

async function getFaceSourceUrl(userId: string) {
    const pr = await db.collection("personas").doc(userId).get();
    const url = pr.exists ? (pr.data() as any).faceKitURL : null;
    if (!url) throw new Error("missing_faceKitURL");
    return url;
}

/**
 * Faceswap:
 *  - Uses persona.faceKitURL as "source"
 *  - Uses the provided baseVideoUrl (Luma CDN MP4) as "target"
 *  - Polls Replicate until terminal
 *  - Uploads result to Cloudinary
 *  - Saves both: faceswap_url (Cloudinary) + faceswap_public_url (Replicate direct URL)
 */
export async function runFaceswap(
    jobId: string,
    userId: string,
    _baseStreamId: string | null,        // kept for signature compatibility; not used
    baseVideoUrl?: string | null         // required path now
): Promise<{ faceswapUrl: string; faceswapPublicUrl: string }> {
    if (!baseVideoUrl || !/^https?:\/\//.test(baseVideoUrl)) {
        throw new Error("no_target_video_url");
    }

    await db.collection("jobs").doc(jobId).update({
        status: "faceswap",
        updated_at: Date.now(),
    });

    const source = await getFaceSourceUrl(userId);

    const pred: ReplicatePrediction = await replicatePredictWaitByVersion(ROOP_VERSION, {
        source,
        target: baseVideoUrl,
        keep_fps: true,
        keep_frames: true,
        enhance_face: false,
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

    const up = await cloudinaryUploadVideoFromUrl(resultUrl, `leadrole-faceswap-${jobId}`);

    await db.collection("jobs").doc(jobId).update({
        "assets.faceswap_url": up.secure_url,
        "assets.faceswap_public_id": up.public_id,
        "assets.faceswap_public_url": resultUrl,
        updated_at: Date.now(),
    });

    return { faceswapUrl: up.secure_url, faceswapPublicUrl: resultUrl };
}