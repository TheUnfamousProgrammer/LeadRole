import { z } from "zod";

export const VideoSpecSchema = z.object({
    aspect_ratio: z.enum(["9:16", "16:9"]).default("9:16"),
    duration: z.enum(["5s", "9s"]).default("5s"),
    resolution: z.enum(["720p"]).default("720p"),
});

export const NarrationSchema = z.object({
    text: z.string().max(1000).optional(),
    voice_profile: z.enum([
        "NarrationMale",
        "NarrationFemale",
        "StoryMale",
        "StoryFemale",
    ]).optional(),
    style: z.string().max(60).optional(),
    emotion: z.string().max(40).optional(),
    language: z.string().max(40).optional(),
    speed: z.number().min(0.5).max(1.5).optional()
});

export const SceneOptionsSchema = z.object({
    sceneType: z.enum(["Vlog", "Cinematic", "Interview", "ProductAd", "Story", "MusicVideo"]).optional(),
    location: z.string().max(120).optional(),
    mood: z.string().max(60).optional(),
    cameraStyle: z.enum(["SelfieVlog", "Handheld", "Tripod", "Drone", "SlowPan"]).optional(),
    lighting: z.string().max(80).optional(),
    outfit: z.string().max(120).optional(),
    video: VideoSpecSchema.optional(),
    narration: NarrationSchema.optional(),
});

export const CreateJobSchema = z.object({
    userId: z.string(),
    prompt: z.string().min(0).max(700).optional(),
    options: SceneOptionsSchema.optional(),
    resumeFrom: z.enum(["auto", "post_luma", "faceswap", "lipsync"]).optional().default("auto"),
    base_video_stream_id: z.string().optional(),
    luma_id: z.string().optional(),
    base_video_url: z.string().url().optional()
});

export const SignupSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6).max(128),
});

export const LoginSchema = SignupSchema;

export const MeSchema = z.object({});

export { z };

export type CreateJobInput = z.infer<typeof CreateJobSchema>;