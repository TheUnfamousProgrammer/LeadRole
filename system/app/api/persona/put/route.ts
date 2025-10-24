import { db } from "@/lib/firestore";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        // Basic shape validation (keep it light for MVP)
        const { userId, gender, faceKitURL, consent } = body;
        if (!userId || !gender || !faceKitURL || consent !== true) {
            return NextResponse.json({ error: "invalid_persona_payload" }, { status: 400 });
        }

        console.log("Saving persona for userId:", userId);

        await db.collection("personas").doc(userId).set(
            {
                ...body,
                updated_at: Date.now(),
            },
            { merge: true }
        );

        console.log("Persona saved successfully for userId:", userId);

        return NextResponse.json({ ok: true });
    } catch (e: any) {
        console.error("Error saving persona:", e.message);
        return NextResponse.json({ error: e.message ?? "internal_error" }, { status: 500 });
    }
}