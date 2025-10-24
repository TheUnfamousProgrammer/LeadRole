import type { StorageAdapter } from "./types";
import { cloudinaryAdapter } from "./cloudinary-adapter";

const DRIVER = (process.env.STORAGE_DRIVER || "cloudinary").toLowerCase();

let adapter: StorageAdapter;
switch (DRIVER) {

    case "cloudinary":
    default:
        adapter = cloudinaryAdapter;
}

export const storage: StorageAdapter = adapter;