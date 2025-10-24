import { db } from "../../lib/firestore";

export async function validateInputs(jobId: string) {
    const doc = await db.collection("jobs").doc(jobId).get();
    if (!doc.exists) throw new Error("job_not_found");
    const j = doc.data() as any;
    if (!j?.prompt) throw new Error("missing_prompt");
    await db.collection("jobs").doc(jobId).update({ status: "validating_inputs", updated_at: Date.now() });
    return j;
}