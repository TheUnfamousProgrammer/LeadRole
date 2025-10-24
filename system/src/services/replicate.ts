// src/services/replicate.ts
const API_BASE = "https://api.replicate.com/v1";
const TOKEN =
    process.env.REPLICATE_API_TOKEN ||
    process.env.REPLICATE_API_KEY ||
    "";

if (!TOKEN) throw new Error("missing_replicate_api_token");

export type ReplicateStatus =
    | "starting"
    | "processing"
    | "succeeded"
    | "failed"
    | "canceled"
    | "aborted";

export type ReplicatePrediction = {
    id: string;
    status: ReplicateStatus;
    output: any;
    error?: any;
    urls?: { get?: string; cancel?: string; stream?: string; web?: string };
    version?: string;
    model?: string;
};

function isTerminal(s: ReplicateStatus) {
    return s === "succeeded" || s === "failed" || s === "canceled" || s === "aborted";
}
function sleep(ms: number) {
    return new Promise((r) => setTimeout(r, ms));
}

export async function replicateCreatePrediction(
    pathOrVersion: { modelPath?: string; version?: string },
    input: Record<string, any>,
    opts?: { webhook?: string }
): Promise<ReplicatePrediction> {
    const headers = {
        Authorization: `Bearer ${TOKEN}`,
        "Content-Type": "application/json",
    };

    if (pathOrVersion.version) {
        const body = {
            version: pathOrVersion.version,
            input,
            ...(opts?.webhook ? { webhook: opts.webhook } : {}),
        };
        const res = await fetch(`${API_BASE}/predictions`, {
            method: "POST",
            headers,
            body: JSON.stringify(body),
        });
        if (!res.ok) {
            const t = await res.text().catch(() => "");
            throw new Error(`replicate_create_${res.status}_${t}`);
        }
        return (await res.json()) as ReplicatePrediction;
    }
    if (pathOrVersion.modelPath) {
        const modelPath = pathOrVersion.modelPath.replace(/^\/+|\/+$/g, "");
        const body = {
            input,
            ...(opts?.webhook ? { webhook: opts.webhook } : {}),
        };
        const res = await fetch(`${API_BASE}/models/${modelPath}/predictions`, {
            method: "POST",
            headers,
            body: JSON.stringify(body),
        });
        if (!res.ok) {
            const t = await res.text().catch(() => "");
            throw new Error(`replicate_create_${res.status}_${t}`);
        }
        return (await res.json()) as ReplicatePrediction;
    }

    throw new Error("replicate_create_missing_version_or_modelPath");
}

export async function replicateGetPrediction(getUrl: string): Promise<ReplicatePrediction> {
    const res = await fetch(getUrl, { headers: { Authorization: `Bearer ${TOKEN}` } });
    if (!res.ok) {
        const t = await res.text().catch(() => "");
        throw new Error(`replicate_get_${res.status}_${t}`);
    }
    return (await res.json()) as ReplicatePrediction;
}

/** Start + poll (version) until terminal */
export async function replicatePredictWaitByVersion(
    version: string,
    input: Record<string, any>,
    opts?: { timeoutMs?: number; pollMs?: number; webhook?: string }
): Promise<ReplicatePrediction> {
    const timeoutMs = opts?.timeoutMs ?? Number(process.env.REPLICATE_TIMEOUT_MS || 15 * 60 * 1000);
    const pollMs = opts?.pollMs ?? Number(process.env.REPLICATE_POLL_MS || 2500);

    let cur = await replicateCreatePrediction({ version }, input, { webhook: opts?.webhook });
    const start = Date.now();

    while (!isTerminal(cur.status)) {
        if (!cur.urls?.get) throw new Error("replicate_missing_get_url");
        if (Date.now() - start > timeoutMs) throw new Error("replicate_poll_timeout");
        await sleep(pollMs);
        cur = await replicateGetPrediction(cur.urls.get);
    }
    return cur;
}

/** Start + poll (modelPath) until terminal */
export async function replicatePredictWaitByModelPath(
    modelPath: string,
    input: Record<string, any>,
    opts?: { timeoutMs?: number; pollMs?: number; webhook?: string }
): Promise<ReplicatePrediction> {
    const timeoutMs = opts?.timeoutMs ?? Number(process.env.REPLICATE_TIMEOUT_MS || 15 * 60 * 1000);
    const pollMs = opts?.pollMs ?? Number(process.env.REPLICATE_POLL_MS || 2500);

    let cur = await replicateCreatePrediction({ modelPath }, input, { webhook: opts?.webhook });
    const start = Date.now();

    while (!isTerminal(cur.status)) {
        if (!cur.urls?.get) throw new Error("replicate_missing_get_url");
        if (Date.now() - start > timeoutMs) throw new Error("replicate_poll_timeout");
        await sleep(pollMs);
        cur = await replicateGetPrediction(cur.urls.get);
    }
    return cur;
}

/** Extract a public MP4-ish URL from Replicate output */
export function extractReplicateVideoUrl(output: any): string | null {
    if (!output) return null;
    if (typeof output === "string" && output.startsWith("http")) return output;
    if (Array.isArray(output)) {
        const hit = output.find((u) => typeof u === "string" && /^https?:\/\//.test(u));
        return hit || null;
    }
    if (output?.video && typeof output.video === "string") return output.video;
    return null;
}