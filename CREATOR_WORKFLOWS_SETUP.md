> Current repair: ElevenLabs support and pipeline correctness changes are documented in [PRODUCTION_REPAIR_NOTES.md](PRODUCTION_REPAIR_NOTES.md). Its verification notes supersede earlier counts below.

# SupoClip: Roblox edits, long streams and Buffer batches

This build adds two separate workflows to the existing application. It is an updated source package, not an installation already running on your computer.

## Install into your existing project

1. Let existing clip jobs and editor exports finish. Back up your existing project folder.
2. Extract the ZIP to a temporary folder. Copy the **contents** of its `supoclip-main` folder into your existing SupoClip folder and replace matching code files. Keep your existing `.env`, database and Docker volumes. Do not create a second nested `supoclip-main` folder.
3. In the existing root `.env`, add `HEYGEN_API_KEY` for narration. Use an existing `OPENAI_API_KEY` or `OPENROUTER_API_KEY` for visual analysis, or set the three optional `ROBLOX_VISION_*` fields shown in `.env.creator.example`. Enter keys locally; do not paste them into chat.
4. Open PowerShell in the existing project folder and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\enable-creator-workflows.ps1
   ```

   This checks that there are no queued/processing tasks or active worker jobs, backs up `.env`, sets the self-hosted limits to 8 hours and 30 clips, validates Compose and rebuilds the backend, worker and frontend. It never deletes database or media volumes. If the checks cannot run, it stops and leaves the installation unchanged.
5. Refresh `http://localhost:3107` with Ctrl+F5 (or your existing configured address).

For an installation that is not running yet, configure the limits in `.env.creator.example` manually, then use your existing SupoClip setup process. The helper is intended for a running installation whose database and worker can be checked.

## Roblox / Forge GUI mode

- Select **Roblox / Forge GUI**. Select one or up to 30 source videos; each build can be up to 10 minutes. One finished story per source is the default. Selecting more requests distinct stories when the source supports them.
- Keep Silvan for the previously approved voice, or browse public HeyGen voices and audition their previews. Set the exact spoken ending and choose typing, flight, blaster, damage, coin, whoosh, pop, impact and reveal sounds.
- The worker samples up to 120 frames per source. It reads visible prompts and actions, builds a scene plan, generates narration, matches the original word timings, renders at natural speed and mixes original procedural effects. It uses the approved full HD vertical layout and optional bold phrase captions.
- **Audio** contains the music library, music toggle and level. Roblox mode uses an included original instrumental if your library is empty. Regular clipping continues to use your existing music-library behavior.
- On the task page, expand **Review Roblox scenes and sound timing**. Change source ranges, narration, or sound offsets/durations and render that clip again. Changing spoken words generates new narration; sound-only adjustments reuse its saved audio. A failed render keeps the previous successful clip. A failed initial build with a saved plan can be corrected and resumed.
- Detection is approximate. Frame sampling can miss a fast shot or a small health-bar change. Preview before enabling automatic publishing; the editor permits corrections. Narration is never sped up to fit: a scene with insufficient footage fails with an instruction to extend its range or shorten its text.
- Plans, evidence, source ranges, word timings, captions and sound stems are saved under the shared uploads volume at `creator-builds/<task-id>`. They persist through normal rebuilds. Audio comes from the active catalog voice; there is no voice-cloning operation.

The HeyGen connection inside ChatGPT does **not** supply a key to this separate web app. Configure an API key locally. Voice and visual-analysis requests consume their respective API allowances. The default speech model is `heygen-voice-1`; it can be set explicitly with `ROBLOX_TTS_MODEL`.

Provider references: [HeyGen speech contract](https://developers.heygen.com/reference/generate-model-speech), [public voice catalog](https://developers.heygen.com/reference/list-audio-voices), [OpenAI image inputs](https://developers.openai.com/api/docs/guides/images-vision).

## Regular clipping and long streams

- Select **Regular clipping** for GTA, reactions and other long videos. It keeps the source speech and game audio and uses the existing transcript-based highlight selection.
- Paste a saved YouTube video/live-replay link, Twitch VOD/clip or Kick VOD/clip. Choose 20, 25 or 30 clips and a length. Add an optional focus such as “GTA reveals and funny reactions.” The existing multi-window analysis searches across the transcript and removes overlapping candidates.
- Eight hours is the new self-hosted default, not a hosted-plan bypass. Existing explicit server limits still apply unless updated. Source download size is bounded; live recordings are also capped at 20 GB. The helper allows up to 16 GB for long remote sources. Uploads retain your existing upload-size limit.
- The requested count is a target. A quiet video or a source with few distinct usable moments can produce fewer clips. Regular clipping does not yet perform whole-stream visual gameplay highlight detection.

## An actively live stream

- In Regular clipping, enable **Record from a live stream link**.
- Paste a specific YouTube live-video link or a Twitch/Kick channel. Choose 5 minutes to 8 hours. The stream must be public and live when the worker starts.
- Recording begins when a worker slot is available. Keep the worker running. Progress shows elapsed recording time. Cancel stops the recording process. A saved completed recording can be reused on a task resume; interrupted recordings are not silently recorded a second time.
- **Clips are generated after the chosen recording window ends.** This release does not continuously publish new highlights every few minutes while the stream is still being captured. For earlier clips, choose a shorter recording window.
- Provider restrictions, unavailable streams, network interruptions or a full recording-size budget can stop a capture. A recording failure is visible on the task; the app does not claim it clipped an inaccessible stream.

## Buffer automation

- Your existing manual **Schedule via Buffer** workflow is retained.
- For hands-off batches, enable **Automatically schedule finished clips in Buffer** before starting. Select an Instagram channel, posts per day and an optional first posting time. The switch is off by default.
- This choice authorizes the app to send the finished clips to that channel. It generates grounded titles/captions/hashtags and schedules each Reel after processing completes.
- Times are evenly spaced and stored in UTC. The picker uses your local time. If processing passes the requested time, posting starts five minutes after completion. Simultaneous source batches reserve later slots on the same channel to avoid identical posting times.
- Buffer key, publishing access, public S3-compatible media hosting, channel status and any enabled email settings are checked. Your existing Buffer plan/queue limits are not bypassed. A queue limit can stop the batch before all 30 are scheduled.
- The task panel shows scheduling progress or **needs attention**. A Buffer failure leaves finished videos available. Previously scheduled or ambiguous submissions are not blindly duplicated on resume. Check Buffer before retrying an uncertain result.
- Changing a Roblox edit with active Buffer publications is blocked. Create a new generation to change an already scheduled edit. There is no automatic deletion or replacement of existing Buffer posts.

## Verification and remaining live checks

Offline checks passed: 21 focused tests for mode validation, live URL restrictions, scene bounds, written-word timing, original SFX headroom/offsets, a real FFmpeg export (scene order, captions, duration, full decode), Buffer spacing, partial failures and duplicate-submission avoidance. The two new control panels passed an isolated strict TypeScript check with the existing UI prop types represented; changed TSX files passed syntax transpilation. Python sources compile.

Not completed in this environment: full frontend production build/lint, full backend suite/PostgreSQL integration, Docker image build, a real live recording, fresh visual-analysis/speech API calls, or real Buffer posting. Windows denied Docker access and frontend dependency installation. The existing storage layer also requires Linux `fcntl`, so full backend execution belongs in the project's Docker environment. No live service was restarted and no posts were submitted during development.

After installation, test one short Roblox upload and one saved-stream batch with automatic publishing off. Then test a five-minute live capture. Finally, test a small Buffer batch on the intended channel before enabling larger automatic batches.

Re-run the focused offline suite from `backend/` with `python -m pytest tests/creator --confcutdir=tests/creator -o addopts= -q`. Run the full project checks and production build in the normal Docker/Linux development environment after installing dependencies.
