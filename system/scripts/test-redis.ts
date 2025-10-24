import IORedis from "ioredis";

(async () => {
    const raw = process.env.REDIS_URL;
    if (!raw) { console.error("REDIS_URL not set"); process.exit(1); }

    const u = new URL(raw);
    const isTls = u.protocol === "rediss:";
    const host = u.hostname;

    const client = new IORedis(raw, {
        ...(isTls ? {
            tls: {
                servername: host,
                rejectUnauthorized: false,
                minVersion: "TLSv1.2",
            },
        } : {}),
        family: 4,
        connectTimeout: 20000,
        maxRetriesPerRequest: null,
        retryStrategy: (times) => Math.min(times * 250, 2000),
    });

    client.on("error", (e) => console.error("[ioredis error]", e.message));

    try {
        console.log("connecting to", raw);
        const pong = await client.ping();
        console.log("PING =>", pong);
    } finally {
        client.disconnect();
    }
})();