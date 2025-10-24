import { NextRequest } from "next/server";
import { verifyToken } from "./jwt";

export function requireUser(req: NextRequest): { userId: string, email: string } {
    const auth = req.headers.get("authorization");
    if (!auth?.startsWith("Bearer ")) throw new Error("unauthorized");
    const token = auth.slice("Bearer ".length);
    const payload = verifyToken<{ sub: string; email: string }>(token);
    if (!payload?.sub) throw new Error("unauthorized");
    return { userId: payload.sub, email: payload.email };
}