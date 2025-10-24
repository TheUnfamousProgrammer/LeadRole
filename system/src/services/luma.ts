const LUMA_API_KEY = process.env.LUMA_API_KEY!;

export async function lumaGenerate(prompt: string, aspect_ratio: string, duration: string) {
    const res = await fetch("https://api.lumalabs.ai/dream-machine/v1/generations", {
        method: "POST",
        headers: {
            accept: "application/json",
            authorization: `Bearer ${LUMA_API_KEY}`,
            "content-type": "application/json"
        },
        body: JSON.stringify({ prompt, model: "ray-2", aspect_ratio, duration })
    });
    if (!res.ok) throw new Error(`Luma generate failed: ${res.status}`);
    return res.json();
}

export async function lumaGetStatus(id: string) {
    const res = await fetch(`https://api.lumalabs.ai/dream-machine/v1/generations/${id}`, {
        headers: { accept: "application/json", authorization: `Bearer ${LUMA_API_KEY}` },
    });
    if (!res.ok) throw new Error(`Luma status failed: ${res.status}`);
    return res.json();
}