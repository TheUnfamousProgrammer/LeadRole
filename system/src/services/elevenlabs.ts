const XI_KEY = process.env.ELEVENLABS_API_KEY!;

type VoiceMap = Record<string, { elevenlabs_voice_id: string }>;

export async function generateTTSMp3Buffer(
    text: string,
    voiceProfile: string | undefined,
    voiceMap: VoiceMap,
    opts?: { style?: string; speed?: number }
) {
    const fallback = voiceMap["NarrationMale"]?.elevenlabs_voice_id || "4dZr8J4CBeokyRkTRpoN";
    const voiceId = (voiceProfile && voiceMap[voiceProfile]?.elevenlabs_voice_id) || fallback;

    const body: any = {
        text,
        voice_settings: {
            stability: 0.5,
            similarity_boost: 0.8,
            style: 0.5,
            speaking_rate: typeof opts?.speed === "number" ? opts.speed : 1.0,
        },
        model_id: "eleven_v3",
    };

    const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
        method: "POST",
        headers: {
            "xi-api-key": XI_KEY,
            "Content-Type": "application/json",
            accept: "audio/mpeg",
        },
        body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`elevenlabs_${res.status}`);
    const arrayBuf = await res.arrayBuffer();
    return Buffer.from(arrayBuf);
}