// worker/src/pipeline/steps/tts.ts
import { db } from "../../lib/firestore";
import { generateTTSMp3Buffer } from "../../../../src/services/elevenlabs";
import { cloudinaryUploadMp3 } from "../../../../src/services/cloudinary";

export interface RunTTSArgs {
    jobId: string;
    userId: string;
    text: string;
    gender: "male" | "female";              // from persona (default upstream if missing)
    style: "narration" | "storytelling";    // derived from options.narration.style/voice_profile
    language?: string;                      // e.g., "en", "ur" (optional; not strictly needed for voice map)
    voice_profile?: string;                 // "NarrationMale" | "NarrationFemale" | "StoryMale" | "StoryFemale"
    speed?: number;                         // 0.5–1.5 (from narration plan)
}

/** Derive profile when not explicitly provided. */
function resolveVoiceProfile(gender: "male" | "female", style: "narration" | "storytelling"): string {
    if (style === "storytelling") return gender === "female" ? "StoryFemale" : "StoryMale";
    return gender === "female" ? "NarrationFemale" : "NarrationMale";
}

export async function runTTS(args: RunTTSArgs) {
    const { jobId, text, gender, style, voice_profile, speed } = args;

    await db.collection("jobs").doc(jobId).update({
        status: "tts_generating",
        updated_at: Date.now(),
    });

    const voicesMod: any = await import("../../../../src/config/el_voices.json", { with: { type: "json" } } as any);
    const VOICE_MAP: Record<string, { elevenlabs_voice_id: string }> = voicesMod.default || voicesMod;

    const chosenProfile = voice_profile || resolveVoiceProfile(gender, style);

    const mp3Buffer = await generateTTSMp3Buffer(
        text,
        chosenProfile,
        VOICE_MAP,
        { style, speed }
    );

    const upload = await cloudinaryUploadMp3(mp3Buffer, `leadrole-tts-${jobId}`);

    await db.collection("jobs").doc(jobId).update({
        "audio.tts_url": upload.secure_url,
        "audio.voice_profile": chosenProfile,
        status: "tts_done",
        updated_at: Date.now(),
    });

    return upload.secure_url as string;
}