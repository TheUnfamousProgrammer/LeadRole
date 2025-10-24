export async function lumaGenerate(prompt: string, aspect_ratio: string, duration: string) {
    const res = await fetch("https://api.lumalabs.ai/dream-machine/v1/generations", {
        method: "POST",
        headers: {
            accept: "application/json",
            authorization: `Bearer ${process.env.LUMA_API_KEY}`,
            "content-type": "application/json"
        },
        body: JSON.stringify({ prompt, model: "ray-2", aspect_ratio, duration })
    });
    if (!res.ok) throw new Error(`Luma generate failed: ${res.status}`);
    return res.json();
}

export async function lumaGet(genId: string) {
    const res = await fetch(`https://api.lumalabs.ai/dream-machine/v1/generations/${genId}`, {
        headers: { accept: "application/json", authorization: `Bearer ${process.env.LUMA_API_KEY}` }
    });
    if (!res.ok) throw new Error(`Luma get failed: ${res.status}`);
    return res.json();
}

export async function cfStreamCopy(url: string) {
    const res = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/stream/copy`,
        {
            method: "POST",
            headers: { Authorization: `Bearer ${process.env.CLOUDFLARE_API_TOKEN}`, "Content-Type": "application/json" },
            body: JSON.stringify({ url })
        }
    );
    if (!res.ok) throw new Error(`CF Stream copy failed: ${res.status}`);
    return res.json();
}