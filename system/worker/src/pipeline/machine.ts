// worker/src/pipeline/machine.ts
import { db } from "../lib/firestore";
import { validateInputs } from "./steps/validate-inputs";
import { generateBase } from "./steps/generate-base-video";
import { uploadBase } from "./steps/upload-base";           // copies Luma MP4 -> storage (Cloudinary now)
import { runFaceswap } from "./steps/faceswap";              // stores faceswap_url + faceswap_public_url
import { runLipsync } from "./steps/lipsync";                // stores lipsync_url
import { burnWatermarkToBuffer } from "./steps/watermark";   // local ffmpeg watermark -> Buffer
import { uploadFinalFromBuffer } from "./steps/finalise";    // storage adapter upload for final Buffer
import { runTTS } from "./steps/tts";                        // generates MP3 -> storage; stores audio.tts_url

type ResumeFrom = "auto" | "post_luma" | "faceswap" | "lipsync";

async function getPersona(
    userId: string
): Promise<{ gender?: "male" | "female" | "other"; faceKitURL?: string } | null> {
    const snap = await db.collection("personas").doc(userId).get();
    return snap.exists ? (snap.data() as any) : null;
}

export async function runPipeline(jobId: string) {
    try {
        await validateInputs(jobId);

        let snap = await db.collection("jobs").doc(jobId).get();
        let job = snap.data() as any;
        if (!job) throw new Error("job_not_found");

        const spec = job.video ?? { aspect_ratio: "9:16", duration: "5s", resolution: "720p" };
        const resumeFrom: ResumeFrom = job.resumeFrom || "auto";


        let baseVideoUrl: string | undefined = job.base_video_url;

        if (!baseVideoUrl) {
            if (resumeFrom === "post_luma" || resumeFrom === "faceswap" || resumeFrom === "lipsync") {
                const startWith = {
                    luma_id: job.vendor_refs?.luma_id || job.luma_id || undefined,
                    base_video_url: job.base_video_url || undefined,
                };
                const { videoUrl } = await generateBase(jobId, job.prompt, spec.aspect_ratio, spec.duration, startWith);
                await uploadBase(jobId, videoUrl);
                baseVideoUrl = videoUrl;
            } else {
                const { videoUrl } = await generateBase(jobId, job.prompt, spec.aspect_ratio, spec.duration);
                await uploadBase(jobId, videoUrl);
                baseVideoUrl = videoUrl;
            }
        } else {
            await uploadBase(jobId, baseVideoUrl);
        }

        snap = await db.collection("jobs").doc(jobId).get();
        job = snap.data() as any;
        const needFaceswap =
            !job.assets?.faceswap_url ||
            resumeFrom === "post_luma" ||
            resumeFrom === "faceswap" ||
            resumeFrom === "lipsync";

        let faceswapUrl: string | undefined = job.assets?.faceswap_url;
        let faceswapPublicUrl: string | undefined = job.assets?.faceswap_public_url;

        if (needFaceswap) {
            const res = await runFaceswap(jobId, job.user_id, null, baseVideoUrl || null);
            faceswapUrl = res.faceswapUrl;
            faceswapPublicUrl = res.faceswapPublicUrl;
        }
        const narration = job.options?.narration;
        let finalCandidateUrl: string = faceswapUrl!;

        if (narration?.text && narration.text.trim().length > 0) {
            const persona = await getPersona(job.user_id);
            const gender = (persona?.gender === "female" ? "female" : "male") as "male" | "female";

            const styleFromProfile = (() => {
                const vp = narration.voice_profile || "";
                if (/story/i.test(vp)) return "storytelling";
                return "narration";
            })();
            const style: "narration" | "storytelling" =
                narration.style && /story/i.test(narration.style) ? "storytelling" : styleFromProfile;

            const language = narration.language || "en";

            const audioUrl = await runTTS({
                jobId,
                userId: job.user_id,
                text: narration.text,
                gender,
                style,
                language,
                voice_profile: narration.voice_profile,
                speed: narration.speed,
            });

            if (!faceswapPublicUrl) {
                throw new Error("missing_faceswap_public_url_for_lipsync");
            }

            const lipsyncStoredUrl = await runLipsync(jobId, faceswapPublicUrl, audioUrl);
            finalCandidateUrl = lipsyncStoredUrl;
        }


        const watermarkUrl =
            process.env.WATERMARK_ASSET_URL ||
            "https://imagedelivery.net/nIXg1hqSCosmvn2DEPXE5A/3e06fb0a-0862-490e-4632-0c2c5390f200/public";

        const watermarkedBuffer = await burnWatermarkToBuffer(jobId, finalCandidateUrl, watermarkUrl);

        const finalUrl = await uploadFinalFromBuffer(jobId, watermarkedBuffer);

        await db.collection("jobs").doc(jobId).update({
            status: "done",
            updated_at: Date.now(),
        });
    } catch (e: any) {
        await db.collection("jobs").doc(jobId).update({
            status: "failed",
            error: { message: e.message },
            updated_at: Date.now(),
        });
        throw e;
    }
}