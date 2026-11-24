# SupoClip Creator Enhancements — Installation

This archive contains the complete SupoClip source project. The archive paths start at the project root, so extract its contents directly into your existing project directory.

## Before extracting

1. Close SupoClip's browser tabs if convenient.
2. Keep your existing root `.env` file. The archive does not include a real `.env` file and must not replace it.
3. Do not delete your existing project directory or Docker volumes. The music library is stored in the existing `uploads` named volume, shared by backend and worker.

## Install on Windows Docker Desktop

1. Download the ZIP.
2. In File Explorer, open `C:\Users\Tejas Bhavsar\supoclip-main`.
3. Extract the ZIP contents directly into this folder. Choose **Replace files** when Windows asks. Do not extract it into a new nested `supoclip-main` folder.
4. Open Command Prompt and run:

```cmd
cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
docker compose config --quiet
docker compose up -d --build backend worker frontend
docker compose ps
```

Do not add `--no-cache` (it needlessly recreates the large Docker build cache). Do not run `docker compose down -v`, `docker volume prune`, or Docker Desktop factory reset.

## Where to add music

Open `http://localhost:3107`, sign in, and refresh with **Ctrl+F5**. On the main video composer, click **Music & hooks** immediately beside **Upload**. Inside the panel:

1. Turn on **Background music**.
2. Pick a mood folder (or **Any clip / general**).
3. Click **Add your music files** and upload MP3, WAV, M4A, AAC, OGG or FLAC tracks (maximum 30 MB each).
4. Adjust **Music level** if needed. The default is 16%; speech ducking reduces music when the original audio is active.
5. Select hook text size and safe-zone position as required. Small is the default.

Music tracks are stored under the persistent Docker `uploads` volume, scoped to your signed-in user. They are not bundled in this source ZIP. They remain available after normal container restarts and image rebuilds when you keep the same Compose project and volumes.

Music is applied to **newly generated clips**. Previously generated clips are not changed automatically. Use music you own or are licensed to use.

## What changed

- The visible **Music & hooks** control is placed directly after **Upload**, before clip-count and other controls, so it is easy to find in the first row/early wrap position.
- The control manages persistent user music uploads, mood folders, on/off, and music volume.
- The task API persists the settings; the worker reads the user's library and selects a track using transcript cues.
- FFmpeg mixes the music below original audio with speech ducking. If no valid track exists or the mix fails, the original clip is kept.
- Small persistent hook text is the default, with Medium/Large and Upper/Middle safe-zone options.
- Existing Buffer code and post publishing logic are unchanged.

## Local source verification

From the project root:

```cmd
python scripts/verify-creator-enhancements.py
```

This checks the main UI control location, frontend upload proxy, backend music-library endpoints, task-to-worker-to-renderer wiring, and shared persistent uploads volume.
