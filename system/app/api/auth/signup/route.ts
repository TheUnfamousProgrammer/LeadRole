import { NextRequest, NextResponse } from "next/server";
import { db } from "../../../../src/lib/firestore";
import { SignupSchema } from "../../../../src/lib/z";
import { hashPassword } from "../../../../src/lib/auth";
import { signToken } from "../../../../src/lib/jwt";

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { email, password } = SignupSchema.parse(body);

        const existing = await db.collection("users").where("email", "==", email.toLowerCase()).limit(1).get();
        if (!existing.empty) {
            return NextResponse.json({ error: "email_in_use" }, { status: 409 });
        }

        const password_hash = await hashPassword(password);
        const now = Date.now();

        const docRef = await db.collection("users").add({
            email: email.toLowerCase(),
            password_hash,
            created_at: now,
            last_login_at: now,
        });

        const token = signToken({ sub: docRef.id, email: email.toLowerCase() });

        return NextResponse.json({
            token,
            user: { id: docRef.id, email: email.toLowerCase() },
        });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 400 });
    }
}