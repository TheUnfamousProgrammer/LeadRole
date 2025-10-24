import { NextRequest, NextResponse } from "next/server";
import { db } from "../../../../src/lib/firestore";
import { LoginSchema } from "../../../../src/lib/z";
import { comparePassword } from "../../../../src/lib/auth";
import { signToken } from "../../../../src/lib/jwt";

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { email, password } = LoginSchema.parse(body);

        const snap = await db.collection("users").where("email", "==", email.toLowerCase()).limit(1).get();
        if (snap.empty) {
            return NextResponse.json({ error: "invalid_credentials" }, { status: 401 });
        }

        const doc = snap.docs[0];
        const user = doc.data() as any;

        const ok = await comparePassword(password, user.password_hash);
        if (!ok) {
            return NextResponse.json({ error: "invalid_credentials" }, { status: 401 });
        }

        await db.collection("users").doc(doc.id).update({ last_login_at: Date.now() });

        const token = signToken({ sub: doc.id, email: user.email });

        return NextResponse.json({
            token,
            user: { id: doc.id, email: user.email },
        });
    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 400 });
    }
}