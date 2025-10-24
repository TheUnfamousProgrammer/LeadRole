# 🎬 LeadRole — AI-Driven Virtual Filmmaking Platform

[![Node.js](https://img.shields.io/badge/Node.js-18.x-brightgreen)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)]()
[![Firestore](https://img.shields.io/badge/Firebase-Firestore-orange)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

**LeadRole** lets anyone become the *lead actor* of their own cinematic story.  
It generates personalized AI videos by combining virtual cinematography, face-swapping, lip-syncing, and voiceover — all orchestrated through a modular production pipeline.

---

## 🧩 System Overview

### 🛠️ Backend — `system/`

Built with **Node.js**, **TypeScript**, and **Firebase Firestore**, the backend coordinates every creative job end-to-end.

#### Key Responsibilities
| Module | Description |
|--------|--------------|
| **API Layer** | Express-based REST API for jobs, personas, and media |
| **Worker Queue** | BullMQ with Redis for async, fault-tolerant processing |
| **Pipeline Steps** | Modular orchestration for `luma`, `faceswap`, `tts`, `lipsync`, `watermark` |
| **Storage** | Cloudinary for assets, Cloudinary Stream for final delivery |
| **Database** | Firestore collections: `users`, `personas`, `jobs` |
| **Vendor Integrations** | Luma (base video), Replicate (AI models), ElevenLabs (TTS), Cloudinary (stream hosting) |

---

### ⚙️ Job Pipeline Flow

flowchart TD
    A[User starts job] --> B[Luma: Base video]
    B --> C[FaceSwap (Replicate Roop)]
    C --> D[TTS (ElevenLabs)]
    D --> E[LipSync (Replicate LipSync-2)]
    E --> F[Watermark & Cloudinary Upload]
    F --> G[Firestore: Job Done ✅]

Each step updates Firestore with:
	•	status (luma_generating, faceswap_running, lipsync_running, etc.)
	•	assets (URLs for progress, faceswap, lipsync, and final output)
	•	vendor_refs (Replicate job IDs, Luma IDs)
	•	error (if any)

The mobile app polls this document to reflect progress live.

⸻

📱 Mobile App — mobile/

A Flutter companion app for iOS and Android, providing a complete cinematic dashboard.

Key Features

Feature	Description
🎭 Persona Creator	Capture selfie + traits to personalize face-swapping
🧾 Scene Wizard	Configure location, mood, lighting, outfit, and camera style
🎙️ Narration Editor	Type or record narration (TTS integrated)
🎬 Production Monitor	Real-time job progress and AI pipeline visualization
📡 Progress Reel	Shows blurred previews & in-progress dailies from Luma
🧰 Download Player	Inline MP4 playback + local save with progress bar

Flutter Stack
	•	State Management: Riverpod
	•	Navigation: GoRouter
	•	Networking: Dio
	•	Playback: video_player
	•	Storage: SharedPreferences
	•	UI: Material 3 + Neon accent design

⸻

🧠 Job Status States

Stage	Firestore Status	Description
🎞️ Base Video	generating_base_video	Luma prompt generating cinematic clip
✅ Base Ready	base_ready	Ready for face swap
🎭 FaceSwap	faceswap_running	Roop model applying user selfie
🎙️ VoiceOver	tts_generating	ElevenLabs generating narration
🔊 LipSync	lipsync_running	Replicate LipSync-2 aligning speech
✨ Watermark	watermarking	Final pass before upload
🏁 Done	done	Final video available
❌ Failed	failed	Pipeline interrupted


⸻

⚙️ Environment Setup

Backend .env

REDIS_URL=redis://...
GOOGLE_APPLICATION_CREDENTIALS=/Users/Apple/...
FIREBASE_PROJECT_ID=...
LUMA_API_KEY=luma-...

MAX_LUMA_WAIT_MS=600000 # 10 minutes     
LUMA_POLL_INTERVAL=15000 # 15 seconds

REPLICATE_API_TOKEN=r8_...

REPLICATE_WAIT_TIMEOUT_MS=900000 # 15 minutes
REPLICATE_VERIFY_POLLS=5 
REPLICATE_VERIFY_INTERVAL_MS=2500 # 3 seconds

# ElevenLabs (TTS)
ELEVENLABS_API_KEY=sk_...

# Cloudinary (to host the MP3 returned by ElevenLabs)
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
CLOUDINARY_UPLOAD_PRESET=lr...

NARRATION_STRICT_LIMIT=true

WATERMARK_ASSET_URL=https://imagedelivery.net/example
WATERMARK_SCALE=0.5
WATERMARK_PAD=32
WATERMARK_MIN_PX=96
WATERMARK_MAX_PX=320

JWT_SECRET=......


⸻

🚀 Running Locally

1️⃣ Backend

cd system
npm install
npm run dev | npm run worker:dev
# Starts Express API and queue worker

2️⃣ Mobile

cd mobile
flutter pub get
flutter run

Ensure your config and Firebase credentials are set up locally.

⸻

🔄 Job Document Example

{
  "id": "1fTnjy0BVF3fqAiz56ZW",
  "user_id": "demo-user-001",
  "prompt": "Vlog style portrait... in Tokyo.",
  "status": "lipsync_running",
  "vendor_refs": {
    "luma_id": "5a3f807e-2e6c-422b-b662-4c138ffc71cd"
  },
  "assets": {
    "progress_video_url": "https://storage.cdn-luma.com/dm-progress/.../40.mp4",
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


⸻

☁️ Deployment

Component	Platform	Notes
API / Worker	Railway.app	Node.js + Firestore + Redis
Storage	Cloudinary + Cloudinary Stream	Fast delivery for generated content
Mobile App	TestFlight / Google Play Internal
Logging	Firestore events + Cloudinary analytics	Unified monitoring


⸻

🧱 Architecture Principles
	•	Modular AI pipeline → each step is independent and retryable
	•	Idempotent jobs → keyed by idempotency_key
	•	Reactive UI → mobile polls Firestore live
	•	Serverless-friendly → designed for Railway / Vercel workers
	•	Human-readable status updates → every pipeline stage logged in Director’s Monitor

⸻

🧰 Tech Stack Summary

Layer	Tech
Backend	Node.js, TypeScript, Firestore, BullMQ, Redis
AI Vendors	Luma, Replicate (Roop, LipSync-2), ElevenLabs
Storage	Cloudinary, Cloudinary Stream
Mobile	Flutter, Riverpod, Dio, GoRouter, video_player
Infra	Railway, Firebase, GitHub Actions
Auth	Email-based (JWT optional, Firestore scoped)


⸻

🧩 Future Roadmap
	•	🌐 Web dashboard for creators
	•	🧾 Billing + credit system
	•	🧱 SDK for custom AI pipeline extensions

⸻

🤝 Contributing

We welcome contributions!
	•	Fork this repo
	•	Create a feature branch (git checkout -b feature/amazing)
	•	Commit and push your changes
	•	Open a PR 🎉


⸻

👨‍🎨 Authors

LeadRole — AI Filmmaking Platform
Built by theunfamourprogrammer
	•	Backend: Node.js + TypeScript + Firestore
	•	Mobile: Flutter + Riverpod + GoRouter

⸻

🪄 License

Licensed under the MIT License © 2025 LeadRole
Use responsibly for creative, educational, and non-malicious purposes.