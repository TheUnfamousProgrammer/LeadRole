# 🎬 LeadRole , AI-Driven Virtual Filmmaking Platform

**LeadRole** transforms users into the lead actor of their own cinematic stories.  
It generates personalized AI videos by combining **virtual cinematography, face-swapping, lip-syncing, and voiceover**, all orchestrated through a modular, fault-tolerant backend pipeline.

---

## 🧩 System Architecture

LeadRole is composed of two main components:

### 🖥️ Backend , `system/`
Built with **Node.js**, **TypeScript**, **Firestore**, and **Redis**.

#### Responsibilities
- **API Layer:** NextJS based REST API for job creation, persona management, and progress tracking.  
- **Worker Pipeline:** BullMQ queue running on Redis, executing modular steps:
  1. **Base Video Generation** (Luma API)
  2. **FaceSwap** (Replicate Roop model)
  3. **Voiceover (TTS)** (ElevenLabs API)
  4. **LipSync** (Replicate LipSync-2 model)
  5. **Watermarking & Upload** (Cloudinary CDN & FFmpeg)

#### Data Flow
1. User submits a prompt & persona via mobile app.  
2. The backend builds an enhanced cinematic prompt using `promptBuilder.ts`.  
3. Jobs are inserted into Firestore and queued in Redis.  
4. Each worker updates Firestore as steps complete, including:
   - `status` → (e.g., `luma_generating`, `faceswap_running`, `done`)
   - `assets` → (e.g., Cloudinary URLs, progress clips, final output)
   - `vendor_refs` → (Replicate/Luma job IDs)
   - `error` → (structured logs for debugging)

Firestore acts as the **single source of truth**, polled live by the Flutter app.

---

### 📱 Mobile App , `mobile/`
Built with **Flutter 3**, using **Riverpod** for state management and **Dio** for API communication.

#### Core Features
| Feature | Description |
|----------|--------------|
| 🎭 **Persona Creator** | Captures selfie + appearance attributes (gender, hair, style, etc.) |
| 🎬 **Scene Wizard** | Wizard-based flow guiding users through location, lighting, and mood setup |
| 🎙️ **Narration Editor** | Requires narration input (text + voice profile) before generation |
| 🧾 **Production Monitor** | Displays real-time job updates via StreamBuilder polling |
| 📡 **Progress Reel** | Shows blurred Luma preview clips (“dailies”) as the pipeline runs |
| 💾 **Inline Player & Download** | Final MP4 preview + local download with progress indicator |

#### UI Technologies
- **State:** Riverpod (reactive, provider-based architecture)  
- **Navigation:** GoRouter  
- **Video:** `video_player` plugin for inline playback  
- **Persistence:** SharedPreferences for auth and settings  
- **Networking:** Dio for REST communication

---

## ⚙️ Production Pipeline

| Step | Backend Label | Description |
|------|----------------|--------------|
| 🎥 Base Generation | `luma_generating` | Generates cinematic base video (Luma API) |
| 📤 Base Ready | `base_ready` | Uploads base MP4 to Cloudinary |
| 🎭 FaceSwap | `faceswap_running` | Applies user’s persona face via Replicate Roop |
| 🎙️ Voiceover | `tts_generating` | Generates audio narration using ElevenLabs |
| 🔊 LipSync | `lipsync_running` | Syncs lip motion and expressions (Replicate LipSync-2) |
| ✨ Watermark | `watermarking` | Adds branding and exports final cut |
| ✅ Done | `done` | Final Cloudinary URL stored and returned to app |

---

## 🧠 Example Job Document

```json
{
  "id": "1fTnjy0BVF3fqAiz56ZW",
  "user_id": "demo-user-001",
  "prompt": "Vlog style portrait... in Tokyo.",
  "status": "lipsync_running",
  "vendor_refs": {
    "luma_id": "5a3f807e-2e6c-422b-b662-4c138ffc71cd"
  },
  "assets": {
    "progress_video_url": "https://storage.cdn-luma.com/.../40.mp4",
    "lipsync_url": null,
    "final_url": null
  },
  "narration_plan": {
    "language": "en",
    "durationSec": 5,
    "text": "Excited to build something today at Fleek"
  },
  "updated_at": 1761330005908
}
```

---

## 🔐 Authentication Flow

- Simple **email + password** system managed on Firestore.  
- Tokenless session (user ID persisted via SharedPreferences, JWT started but not fully implemented.).  
- All generation endpoints are public (for MVP).  
- Auth persistence handled by `authProvider` (Riverpod).

---

## 🧰 Tech Stack Summary

| Layer | Tools |
|--------|-------|
| **Backend** | Node.js, TypeScript, Firestore, BullMQ, Redis |
| **AI Vendors** | Luma, Replicate (Roop, LipSync-2), ElevenLabs |
| **Storage/CDN** | Cloudinary, Cloudinary Stream |
| **Mobile** | Flutter, Riverpod, Dio, GoRouter, video_player |
| **Infrastructure** | Railway (API + Worker), Firebase (Auth + DB) |

---

## 🚀 Setup Instructions

### Backend
```bash
cd system
npm install
npm run dev
# or for worker
npm run worker:dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

Ensure `.env` contains:

```bash
REDIS_URL=redis://...
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
FIREBASE_PROJECT_ID=...
LUMA_API_KEY=...
REPLICATE_API_TOKEN=...
ELEVENLABS_API_KEY=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

---

## ☁️ Deployment

| Component | Platform | Notes |
|------------|-----------|-------|
| API + Worker | Railway.app | Handles async job queue |
| Storage | Cloudinary | Hosts videos and assets |
| Database | Firestore | Tracks users and jobs |
| Mobile | Flutter | Built for iOS + Android |
| Monitoring | Firestore logs + Cloudinary analytics |

---

## 👨‍💻 Author

**LeadRole**  
Created by [TheUnfamousProgrammer](https://github.com/TheUnfamousProgrammer)  
Built as a full-stack AI filmmaking proof of concept , designed, coded, and integrated from scratch in 72 hours.

---

## 🪄 License

Licensed under the **MIT License © 2025 LeadRole**
