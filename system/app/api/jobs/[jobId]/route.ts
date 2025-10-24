import { requireUser } from "@/lib/authGuard";
import { db } from "@/lib/firestore";
import { NextRequest, NextResponse } from "next/server";

// GET /api/jobs/:jobId
export async function GET(req: NextRequest, context: { params: { jobId: string } }) {
    try {
        const { jobId } = context.params;
        if (!jobId) {
            return NextResponse.json({ error: "missing_jobId" }, { status: 400 });
        }

        const doc = await db.collection("jobs").doc(jobId).get();
        if (!doc.exists) return NextResponse.json({ error: "not_found" }, { status: 404 });

        const data = doc.data() as any;


        return NextResponse.json({ id: doc.id, ...data });
    } catch (e: any) {
        const code = e?.message === "unauthorized" ? 401 : 500;
        return NextResponse.json({ error: e?.message || "internal_error" }, { status: code });
    }
}