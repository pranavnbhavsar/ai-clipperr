# SupoClip – Creator Enhancements

This update keeps the existing SupoClip clip-generation pipeline, task history, editor, publishing integrations, and Buffer code. It adds optional enhancements to newly generated clips.

## What's new

### On-screen hook

- The existing AI-generated `hook_title` is burned into the exported clip when available.
- The hook lasts for the full clip, with a short entrance fade.
- Small is the default; Medium and Large are selectable per new batch.
- Placement can be Auto, Upper center, or Middle safe zone.
- The layout avoids the bottom caption/username region and reserves extra horizontal space around the text.
- This is a conservative Instagram-style safe-zone layout, not computer-vision tracking of moving faces or objects. Review the preview before publishing.

### Music library and mixing

1. On the home-page video composer, click **Music & hooks**. This button is placed immediately beside **Upload**, before the clip-count and caption controls so it remains easy to find on desktop and narrow screens.
2. Turn on **Background music** inside the panel.
3. Upload tracks you own or are licensed to use. Supported formats: MP3, WAV, M4A, AAC, OGG and FLAC; maximum 30 MB per file.
4. Optionally assign each uploaded track to a mood folder: Hype, Funny, Emotional, Luxury, Neutral or Any clip.
5. SupoClip matches transcript words to a mood category and selects a track from that category, falling back to the general library.
6. Music is mixed under the original clip audio. When source audio exists, FFmpeg side-chain compression lowers the music under speech. The original clip is retained if the mix fails.

The mood matcher is a lightweight transcript-keyword classifier, not a separate audio-emotion AI model. Upload a small, well-organized music library to improve selection quality. Music is only added when at least one usable library track exists.

### Subtitles

- Word-synced subtitles remain available in the existing caption controls.
- They are off by default for new tasks and can be switched on per task.
- Hook text is independent from subtitles.

### Existing post metadata

The existing social composer and caption-generation endpoint remain unchanged. When a supported social provider is configured, opening the clip post composer can generate a title, caption and hashtags for that clip. This update does not generate captions automatically for every clip during rendering, and it does not repair or alter Buffer's current auto-posting workflow.

## Music storage

Music files are stored under `TEMP_DIR/music-library/<user-id>/<mood>` (in the default Docker Compose setup, `/app/uploads/music-library`). Backend and worker share the existing `uploads` named volume, so the user's music library persists through container rebuilds and restarts. It is not included in the source ZIP.

## Install on the existing Windows Docker project

1. Back up the project folder. Keep the existing root `.env` outside the ZIP and do not replace it with `.env.example`.
2. Extract the full project ZIP into the existing `C:\Users\Tejas Bhavsar\supoclip-main` folder. Choose Replace files. The ZIP does not contain `.env`, live database data or Docker volumes.
3. In Command Prompt run:

   ```cmd
   cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
   docker compose config --quiet
   docker compose up -d --build backend worker frontend
   docker compose ps
   ```

4. Open `http://localhost:3107`, refresh with Ctrl+F5, and click **Music & hooks** beside **Upload** in the main composer. Upload a few cleared music tracks there.
5. Generate one short test task and listen to the exported clip before generating a larger batch. Confirm that speech remains clear and the hook is not obscuring the main subject.

Do not run `docker compose down -v`, `docker volume prune`, or Docker Desktop factory reset. Keep the same project folder so Compose reuses the existing named volumes and database.

## Validation notes

Use `python scripts/verify-creator-enhancements.py` from the project root for the source-wiring checks. The check confirms the visible composer control is positioned immediately after Upload and before clip-count controls, checks the music-library proxy/API, verifies the task setting is persisted and passed to the worker renderer, and confirms backend/worker use the same persistent uploads volume. Python source compilation and focused mood-selection, hook-layout and FFmpeg audio-mix smoke checks were run in the packaging environment. The FFmpeg side-chain filter was exercised against a synthetic video with audio. The complete backend test suite, production frontend build, Windows Docker build, real Backblaze upload and live Instagram publication were not run here. Buffer's existing implementation is preserved and not claimed as fixed or verified.
