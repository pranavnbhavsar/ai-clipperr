SupoClip exact clip-count fix

Why this patch exists
- The transcript prompt previously asked for "up to N" clips, so the AI could return fewer than selected.
- Fast mode could cap clips at FAST_MODE_MAX_CLIPS even when the user explicitly requested a larger count.

Changes
- A requested count is now an exact target when the source has enough distinct, valid moments.
- If the first analysis returns fewer than requested, the backend makes one completion pass asking for additional non-overlapping clips.
- Explicit requested_clip_count now overrides the fast-mode default ceiling; MAX_CLIPS remains the administrator hard cap.

Install on Windows
1. Back up C:\Users\Tejas Bhavsar\supoclip-main.
2. Extract this ZIP into the project root (the directory containing docker-compose.yml), preserving the relative backend/... paths and allowing these files to be replaced.
3. Open .env and ensure it contains MAX_CLIPS=10. If it is lower, change the existing value to 10. Do not create duplicate MAX_CLIPS entries.
4. In CMD, run:
   cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
   docker compose up -d --build backend worker
5. Wait for the build to finish, then run:
   docker compose ps
6. Start a NEW generation job, select 10 clips, and test again. Existing tasks keep their original selected clip list.

Note
The app tries to return the requested number when enough distinct, valid moments exist. It will not fabricate dialogue or timestamps, and very short videos or transcripts with too few suitable moments can still return fewer. If the new task still returns fewer than requested, capture:
   docker compose logs --tail=150 backend worker
and inspect the effective MAX_CLIPS setting inside the backend and worker containers.

This patch does not change .env, erase data, or delete Docker volumes.
