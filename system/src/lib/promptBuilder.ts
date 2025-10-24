export type Persona = {
    gender: "male" | "female" | "other";
    age?: number;
    age_range?: string;
    ethnicity?: string;
    skin_tone?: string;
    hair?: string;
    beard?: string;
    build?: string;
};

export type SceneOptions = {
    sceneType?: "Vlog" | "Cinematic" | "Interview" | "ProductAd" | "Story" | "MusicVideo";
    location?: string;
    mood?: string;
    cameraStyle?: "SelfieVlog" | "Handheld" | "Tripod" | "Drone" | "SlowPan";
    lighting?: string;
    outfit?: string;
    video?: { aspect_ratio?: "9:16" | "16:9"; duration?: "5s" | "9s"; resolution?: "720p" };
    narration?: { text?: string; voice_id?: string };
};

export function buildPrompt(persona: Persona | null, opts: SceneOptions = {}, userPrompt?: string) {
    const p: Partial<Persona> = persona ?? {};
    const genderWord = p.gender === "female" ? "female" : p.gender === "male" ? "male" : "person";
    const agePart = p.age ? `${p.age} years old` : (p.age_range ?? "mid-20s");
    const ethnicityPart = p.ethnicity ? `of ${p.ethnicity} appearance` : "of unspecified appearance";
    const skin = p.skin_tone ? `${p.skin_tone} skin tone` : "";
    const hair = p.hair ? p.hair : "";
    const beard = p.gender === "male" && p.beard ? p.beard : "";
    const build = p.build || "average build";
    const outfit = opts.outfit || "casual clothing";

    const scene = opts.sceneType || "Vlog";
    const cam =
        opts.cameraStyle === "Tripod" ? "static tripod framing" :
            opts.cameraStyle === "Drone" ? "aerial tracking shots" :
                opts.cameraStyle === "SlowPan" ? "slow panning movement" :
                    opts.cameraStyle === "Handheld" ? "handheld natural movement" :
                        "front-facing selfie vlog framing at arm’s length";

    const location = opts.location ? `in ${opts.location}` : "in a lively modern city";
    const mood = opts.mood ? `The mood is ${opts.mood}.` : "";
    const lighting =
        opts.lighting ? `Lighting: ${opts.lighting}.` :
            (scene === "Vlog" ? "Lighting: practical city lights with good facial illumination." : "Lighting: cinematic, face well exposed.");

    const faceswapConstraints =
        "The subject’s face remains centered, unmasked, unobstructed, and clearly visible at all times for robust faceswap. No helmets, masks, heavy sunglasses, or occlusions. The user should be talking during the video for best lip-sync results.";

    const cinematic =
        "Cinematic rendering, shallow depth of field, realistic micro-expressions, natural skin, no distortion, no glitch.";

    const narrationHint = opts.narration?.text
        ? `Optional voiceover/narration is provided separately for dubbing: "${opts.narration.text}".`
        : "No in-scene dialogue required; narration may be added later via TTS.";

    const sceneLead =
        scene === "Interview" ? "Interview-style portrait." :
            scene === "Cinematic" ? "Cinematic character moment." :
                scene === "ProductAd" ? "Product-style hero shot with the subject as the hero." :
                    scene === "Story" ? "Short story beat focused on the subject." :
                        scene === "MusicVideo" ? "Music-video inspired performance moment." :
                            "Vlog style portrait.";

    const roleLine =
        p.gender === "female"
            ? `A ${genderWord} ${agePart} ${ethnicityPart}, ${skin}${skin && (hair || beard) ? ", " : ""}${hair}${hair && beard ? ", " : ""}${beard}, ${build}, wearing ${outfit}.`
            : `A ${genderWord} ${agePart} ${ethnicityPart}, ${skin}${skin && (hair || beard) ? ", " : ""}${hair}${hair && beard ? ", " : ""}${beard}, ${build}, wearing ${outfit}.`;

    const userAdd = userPrompt ? `Additional user context: ${userPrompt}.` : "";

    const prompt = `
    ${sceneLead} ${roleLine}
    The scene takes place ${location}. The camera uses ${cam} and keeps the face framed and well-lit. The main character is the focus and will always be facing straight.
    ${mood} ${lighting}
    ${faceswapConstraints}
    ${cinematic}
    ${narrationHint}
    ${userAdd}
  `.replace(/\s+/g, " ").trim();

    return prompt;
}