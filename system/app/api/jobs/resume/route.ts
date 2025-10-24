import { NextRequest, NextResponse } from "next/server";
import { db } from "../../../../src/lib/firestore";
import { jobsQueue } from "../../../../src/lib/redis";

export async function POST(req: NextRequest) {
    const { jobId, resumeFrom } = await req.json();
    if (!jobId) return NextResponse.json({ error: "missing jobId" }, { status: 400 });

    await db.collection("jobs").doc(jobId).set({ resumeFrom: resumeFrom || "post_luma", status: "queued", updated_at: Date.now() }, { merge: true });
    await jobsQueue.add("run", { jobId }, { removeOnComplete: 100, removeOnFail: 100 });
    return NextResponse.json({ ok: true });
}