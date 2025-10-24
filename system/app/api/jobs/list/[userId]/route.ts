import { requireUser } from "@/lib/authGuard";
import { db } from "@/lib/firestore";
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest, context: { params: { userId: string } }) {
    try {
        const { userId } = context.params;
        if (!userId) {
            return NextResponse.json({ error: "missing_userId" }, { status: 400 });
        }
        const { searchParams } = new URL(req.url);
        const status = searchParams.get("status");
        const limit = Math.min(parseInt(searchParams.get("limit") || "20", 10), 50);
        const cursor = searchParams.get("cursor");

        let q = db.collection("jobs")
            .where("user_id", "==", userId)
            .orderBy("created_at", "desc");

        if (status) q = q.where("status", "==", status);
        if (cursor) q = q.startAfter(Number(cursor)); cursor

        const snap = await q.limit(limit).get();

        const items = snap.docs.map(d => {
            const x = d.data() as any;
            return {
                id: d.id,
                status: x.status,
                created_at: x.created_at,
                preview_url: x.assets?.final_url || x.assets?.lipsync_url || x.assets?.faceswap_url || x.assets?.base_video_url || null,
                duration: x.video?.duration || null,
                aspect_ratio: x.video?.aspect_ratio || null,
            };
        });

        const nextCursor = snap.size === limit ? String(items[items.length - 1]?.created_at) : null;

        return NextResponse.json({ items, nextCursor });
    } catch (e: any) {
        const code = e?.message === "unauthorized" ? 401 : 500;
        return NextResponse.json({ error: e?.message || "internal_error" }, { status: code });
    }
}