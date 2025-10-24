import { NextRequest, NextResponse } from "next/server";
import { db } from "../../../../src/lib/firestore";
import { CreateJobSchema } from "../../../../src/lib/z";
import { buildPrompt, type Persona } from "../../../../src/lib/promptBuilder";

async function fetchPersona(userId: string): Promise<Persona | null> {
    const snap = await db.collection("personas").doc(userId).get();
    return snap.exists ? (snap.data() as Persona) : null;
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const parsed = CreateJobSchema.parse(body);
        const persona = await fetchPersona(parsed.userId);
        const finalPrompt = buildPrompt(persona, parsed.options as any, parsed.prompt);
        return NextResponse.json({ prompt: finalPrompt });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 400 });
    }
}