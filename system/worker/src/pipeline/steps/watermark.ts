import { db } from "../../lib/firestore";
import { randomBytes } from "crypto";
import { promises as fs } from "fs";
import path from "path";
import os from "os";
import { spawn, type StdioOptions } from "child_process";
import ffmpegStatic from "ffmpeg-static";
import { path as ffprobeStaticPath } from "ffprobe-static";

const DEBUG = process.env.DEBUG_WATERMARK === "1";

// ENV tunables (with sane defaults)
const SCALE_ENV = Number(process.env.WATERMARK_SCALE ?? "0.18");      // fraction of shorter side
const PAD_ENV = Number(process.env.WATERMARK_PAD ?? "32");        // px from bottom-right
const MIN_W_ENV = Number(process.env.WATERMARK_MIN_PX ?? "96");       // px floor
const MAX_W_ENV = Number(process.env.WATERMARK_MAX_PX ?? "320");      // px ceiling

function resolveFfmpegPath() {
    return process.env.FFMPEG_PATH || (ffmpegStatic as string) || "ffmpeg";
}
function resolveFfprobePath() {
    return process.env.FFPROBE_PATH || ffprobeStaticPath || "ffprobe";
}

function run(cmd: string, args: string[]) {
    return new Promise<void>((resolve, reject) => {
        const stdio: StdioOptions = DEBUG ? ["ignore", "inherit", "inherit"] : ["ignore", "ignore", "inherit"];
        const ps = spawn(cmd, args, { stdio });
        ps.on("error", reject);
        ps.on("close", (code) => (code === 0 ? resolve() : reject(new Error(`${cmd} exit ${code}`))));
    });
}

async function downloadToFile(url: string, fullPath: string, expected: "video" | "image") {
    const r = await fetch(url);
    if (!r.ok) throw new Error(`download_${expected}_${r.status}`);
    const ct = (r.headers.get("content-type") || "").toLowerCase();
    if (expected === "image" && !ct.startsWith("image/")) {
        throw new Error(`watermark_not_image content-type=${ct || "unknown"}`);
    }
    const buf = Buffer.from(await r.arrayBuffer());
    if (expected === "image" && buf.length < 1000) {
        throw new Error(`watermark_too_small size=${buf.length}`);
    }
    await fs.writeFile(fullPath, buf);
}

async function probeDimensions(videoPath: string) {
    const args = [
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "json",
        videoPath,
    ];
    const ps = spawn(resolveFfprobePath(), args, { stdio: ["ignore", "pipe", "inherit"] });
    let out = "";
    ps.stdout.on("data", (d) => (out += d.toString()));
    const code: number = await new Promise((res) => ps.on("close", res as any));
    if (code !== 0) throw new Error(`ffprobe_exit_${code}`);
    const json = JSON.parse(out);
    const st = json?.streams?.[0];
    if (!st?.width || !st?.height) throw new Error("ffprobe_no_dims");
    return { width: st.width as number, height: st.height as number };
}

/**
 * Burn a watermark (PNG) bottom-right.
 * - Size = clamp( round(shorter_side * SCALE), MIN_W, MAX_W )
 * - Padding from edges = PAD
 * - ENV tunables: WATERMARK_SCALE, WATERMARK_PAD, WATERMARK_MIN_PX, WATERMARK_MAX_PX
 * - DEBUG_WATERMARK=1 enables logs, bigger overlay, translucent yellow box, and keeps tmp dir with debug_frame.png
 */
export async function burnWatermarkToBuffer(
    jobId: string | null,
    inputVideoUrl: string,
    watermarkPngUrl: string
): Promise<Buffer> {
    if (jobId) {
        await db.collection("jobs").doc(jobId).set(
            { status: "watermarking", updated_at: Date.now() },
            { merge: true }
        );
    }

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), `leadrole-${randomBytes(3).toString("hex")}-`));
    const inPath = path.join(tmpDir, "input.mp4");
    const wmPath = path.join(tmpDir, "watermark.png");
    const scaledWm = path.join(tmpDir, "wm_scaled.png");
    const outPath = path.join(tmpDir, "output.mp4");
    const debugFrame = path.join(tmpDir, "debug_frame.png");

    try {
        await downloadToFile(inputVideoUrl, inPath, "video");
        await downloadToFile(watermarkPngUrl, wmPath, "image");

        const { width, height } = await probeDimensions(inPath);
        const shorter = Math.min(width, height);

        const SCALE = DEBUG ? Math.max(SCALE_ENV, 0.20) : SCALE_ENV;
        const PAD = DEBUG ? Math.max(PAD_ENV, 40) : PAD_ENV;
        const MIN_W = MIN_W_ENV;
        const MAX_W = MAX_W_ENV;

        const target = Math.round(shorter * SCALE);
        const wmWidth = Math.max(MIN_W, Math.min(MAX_W, target));

        if (DEBUG) {
            console.error(`[watermark] video=${width}x${height} shorter=${shorter} scale=${SCALE} wmWidth=${wmWidth} pad=${PAD}`);
        }

        await run(resolveFfmpegPath(), [
            ...(DEBUG ? ["-loglevel", "verbose"] : []),
            "-y",
            "-i", wmPath,
            "-vf", `scale=${wmWidth}:-1:flags=lanczos`,
            scaledWm,
        ]);

        const filters = DEBUG
            ? `[0:v]format=yuv420p,drawbox=x=iw-${wmWidth + PAD}:y=ih-${Math.round(wmWidth / 2) + PAD}:w=${wmWidth}:h=${Math.round(wmWidth / 2)}:color=yellow@0.3:t=fill[base];` +
            `[1:v]format=rgba,colorchannelmixer=aa=0.90[wm];` +
            `[base][wm]overlay=main_w-overlay_w-${PAD}:main_h-overlay_h-${PAD}[v]`
            : `[1:v]format=rgba,colorchannelmixer=aa=1.0[wm];` +
            `[0:v][wm]overlay=main_w-overlay_w-${PAD}:main_h-overlay_h-${PAD}[v]`;

        await run(resolveFfmpegPath(), [
            ...(DEBUG ? ["-loglevel", "verbose"] : []),
            "-y",
            "-i", inPath,
            "-i", scaledWm,
            "-filter_complex", filters,
            "-map", "[v]",
            "-map", "0:a?",
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "20",
            "-pix_fmt", "yuv420p",
            "-c:a", "copy",
            "-movflags", "+faststart",
            "-shortest",
            outPath,
        ]);

        if (DEBUG) {
            await run(resolveFfmpegPath(), ["-y", "-i", outPath, "-frames:v", "1", debugFrame]);
            const exists = await fs.access(debugFrame).then(() => true).catch(() => false);
            console.error(exists ? `[watermark] wrote debug frame: ${debugFrame}` : `[watermark] failed to write debug frame`);
            console.error(`[watermark] tmp kept for debug: ${tmpDir}`);
        }

        return await fs.readFile(outPath);
    } finally {
        if (!DEBUG) {
            await Promise.allSettled([fs.rm(tmpDir, { recursive: true, force: true })]);
        }
    }
}