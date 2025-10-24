import { db } from "../../lib/firestore";
import { cloudinaryUploadVideoFromUrl } from "../../../../src/services/cloudinary";

export async function uploadBase(jobId: string, videoUrl: string) {
    await db.collection("jobs").doc(jobId).update({ status: "uploading_base", updated_at: Date.now() });

    const up = await cloudinaryUploadVideoFromUrl(videoUrl, `leadrole-base-${jobId}`);

    await db.collection("jobs").doc(jobId).update({
        "assets.base_video_url": up.secure_url,
        "assets.base_public_id": up.public_id,
        updated_at: Date.now(),
    });

    return up.secure_url;
}