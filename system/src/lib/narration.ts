export type NarrationPlan = {
    language: string;
    durationSec: number;
    words: number;
    maxWords: number;
    speakingRate: number;
    trimmed: boolean;
    text: string;
};

const BASE_WPS: Record<string, number> = {
    "en": 2.4,
    "en-US": 2.4,
    "ur": 2.1,
    "ur-PK": 2.1,
    "hi": 2.1,
};

function clamp(n: number, lo: number, hi: number) {
    return Math.max(lo, Math.min(hi, n));
}

/**
 * Compute narration plan:
 * - caps words to max for the target duration
 * - computes a speaking_rate (0.5–1.5) to fit text into duration
 * Strategy: try to keep speaking_rate near 1.0. If text is short, slow down a bit.
 */
export function buildNarrationPlan(
    rawText: string,
    durationSec: 5 | 9,
    language: string = "en",
    opts?: { strict?: boolean; softness?: number }
): NarrationPlan {
    const words = rawText.trim().split(/\s+/).filter(Boolean);
    const langKey = BASE_WPS[language] ? language : (language.split("-")[0] || "en");
    const wps = BASE_WPS[langKey] ?? 2.3;

    const softness = typeof opts?.softness === "number" ? opts!.softness : 0.92;
    const maxWords = Math.floor(wps * durationSec * softness);

    let trimmed = false;
    let finalWords = words;

    if (finalWords.length > maxWords) {
        if (opts?.strict) {
            const err: any = new Error("narration_too_long");
            err.meta = { maxWords, provided: finalWords.length };
            throw err;
        } else {
            finalWords = finalWords.slice(0, maxWords);
            trimmed = true;
        }
    }

    const rate = clamp(finalWords.length / (wps * durationSec), 0.5, 1.5);

    return {
        language: langKey,
        durationSec,
        words: finalWords.length,
        maxWords,
        speakingRate: rate,
        trimmed,
        text: finalWords.join(" "),
    };
}