import { db } from "../../lib/firestore";
import { storage } from "../../../../src/services/storage/";

export async function uploadFinalFromBuffer(jobId: string, videoBuffer: Buffer) {
    const key = `leadrole-final-${jobId}`;
    const res = await storage.putVideo(videoBuffer, key, "video/mp4");

    await db.collection("jobs").doc(jobId).update({
        "assets.final_url": res.url,
        "assets.final_id": res.id,
        updated_at: Date.now(),
    });

    return res.url;
}