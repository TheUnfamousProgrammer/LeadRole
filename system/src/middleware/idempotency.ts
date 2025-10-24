import type { NextRequest } from "next/server";
export function requireIdempotencyKey(req: NextRequest): string {
    const key = req.headers.get("Idempotency-Key") || req.headers.get("idempotency-key");
    if (!key) throw new Error("Missing Idempotency-Key header");
    return key;
}