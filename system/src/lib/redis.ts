import { Queue } from "bullmq";
import IORedis from "ioredis";

const url = process.env.REDIS_URL!;
const isTls = url.startsWith("rediss://") || url.includes("ssl=true");

export const jobsQueue = new Queue("leadrole.jobs", {
    connection: new IORedis(url, {
        ...(isTls ? { tls: { rejectUnauthorized: false, minVersion: "TLSv1.2" } } : {}),
        family: 4,
        maxRetriesPerRequest: null, // BULLMQ
        enableReadyCheck: false,
        connectTimeout: 20000,
        retryStrategy: (times) => Math.min(times * 250, 2000),
    }),
});