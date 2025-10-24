import IORedis from "ioredis";

export async function GET() {
    try {
        const url = process.env.REDIS_URL!;
        const isTls = url.startsWith("rediss://") || url.includes("ssl=true");
        const client = new IORedis(url, isTls ? { tls: { rejectUnauthorized: false } } : {});
        const pong = await client.ping();
        client.disconnect();
        return new Response(JSON.stringify({ ok: true, pong }));
    } catch (e: any) {
        return new Response(JSON.stringify({ ok: false, error: e.message }), { status: 500 });
    }
}