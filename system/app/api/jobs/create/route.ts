import { NextRequest, NextResponse } from "next/server";
import { db } from "../../../../src/lib/firestore";
import { jobsQueue } from "../../../../src/lib/redis";
import { CreateJobSchema } from "../../../../src/lib/z";
import { requireIdempotencyKey } from "../../../../src/middleware/idempotency";
import { buildPrompt, type Persona } from "../../../../src/lib/promptBuilder";
import { buildNarrationPlan } from "../../../../src/lib/narration";
import { requireUser } from "../../../../src/lib/authGuard";

async function fetchPersona(userId: string): Promise<Persona | null> {
    const snap = await db.collection("personas").doc(userId).get();
    return snap.exists ? (snap.data() as Persona) : null;
}

export async function POST(req: NextRequest) {
    try {

        const idemKey = requireIdempotencyKey(req);

        const body = await req.json();
        const parsed = CreateJobSchema.parse(body);


        const existing = await db
            .collection("jobs")
            .where("idempotency_key", "==", idemKey)
            .limit(1)
            .get();

        if (!existing.empty) {
            const doc = existing.docs[0];
            return NextResponse.json({ jobId: doc.id, reused: true });
        }

        const persona = await fetchPersona(parsed.userId);
        const finalPrompt = buildPrompt(persona, parsed.options as any, parsed.prompt);

        const v = parsed.options?.video ?? { aspect_ratio: "9:16", duration: "5s", resolution: "720p" };
        const durationSec: 5 | 9 = v.duration === "9s" ? 9 : 5;

        let narrationPlan: ReturnType<typeof buildNarrationPlan> | null = null;
        if (parsed.options?.narration?.text) {
            const strict = (process.env.NARRATION_STRICT_LIMIT || "true").toLowerCase() === "true";
            try {
                narrationPlan = buildNarrationPlan(
                    parsed.options.narration.text,
                    durationSec,
                    parsed.options.narration.language || "en",
                    { strict }
                );
            } catch (e: any) {
                if (e?.message === "narration_too_long") {
                    return NextResponse.json(
                        {
                            error: "Narration too long",
                            maxWords: e.meta?.maxWords,
                            provided: e.meta?.provided,
                        },
                        { status: 400 }
                    );
                }
                throw e;
            }
        }

        const finalNarration = parsed.options?.narration
            ? {
                ...parsed.options.narration,
                text: narrationPlan ? narrationPlan.text : parsed.options.narration.text,
                speed: narrationPlan ? narrationPlan.speakingRate : parsed.options.narration.speed,
            }
            : undefined;

        const now = Date.now();
        const jobDoc = await db.collection("jobs").add({
            user_id: parsed.userId,
            original_prompt: parsed.prompt ?? "",
            prompt: finalPrompt,
            options: parsed.options ? { ...parsed.options, narration: finalNarration } : null,
            video: v,
            status: "queued",
            idempotency_key: idemKey,
            created_at: now,
            updated_at: now,

            narration_plan: narrationPlan,

            resumeFrom: parsed.resumeFrom ?? "auto",
            base_video_stream_id: parsed.base_video_stream_id ?? null,
            base_video_url: parsed.base_video_url ?? null,
            luma_id: parsed.luma_id ?? null,
        });

        await jobsQueue.add("run", { jobId: jobDoc.id }, { removeOnComplete: 100, removeOnFail: 100 });

        return NextResponse.json({ jobId: jobDoc.id, prompt: finalPrompt });
    } catch (e: any) {
        const status = e?.message === "unauthorized" ? 401 : 400;
        return NextResponse.json({ error: e.message }, { status });
    }
}