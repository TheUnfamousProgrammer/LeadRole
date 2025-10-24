import { Worker } from "bullmq";
import IORedis from "ioredis";
import { runPipeline } from "./pipeline/machine";

const url = process.env.REDIS_URL!;
const isTls = url.startsWith("rediss://") || url.includes("ssl=true");

const connection = new IORedis(url, {
    ...(isTls ? { tls: { rejectUnauthorized: false, minVersion: "TLSv1.2" } } : {}),
    family: 4,
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
    connectTimeout: 20000,
    retryStrategy: (times) => Math.min(times * 250, 2000),
});

const worker = new Worker(
    "leadrole.jobs",
    async (job) => runPipeline((job.data as any).jobId),
    { connection }
);

worker.on("completed", (job) => console.log("completed", job.id));
worker.on("failed", (job, err) => console.error("failed", job?.id, err));