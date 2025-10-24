import { requireUser } from "@/lib/authGuard";
import { db } from "@/lib/firestore";
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest, context: { params: { userId: string } }) {
    try {
        const { userId } = context.params;
        if (!userId) {
            return NextResponse.json({ error: "missing_userId" }, { status: 400 });
        }

        const doc = await db.collection("users").doc(userId).get();
        if (!doc.exists) return NextResponse.json({ error: "not_found" }, { status: 404 });

        const data = doc.data() as any;


        return NextResponse.json({ id: doc.id, ...data });
    } catch (e: any) {
        const code = e?.message === "unauthorized" ? 401 : 500;
        return NextResponse.json({ error: e?.message || "internal_error" }, { status: code });
    }
}