# Creator pipeline repair

The actual project has been updated in place. The complete source package excludes credentials, database volumes, uploads, dependency folders, caches and the duplicate nested source folder.

## What changed

- Added ElevenLabs alongside HeyGen, with a provider selector, voice catalog and previews. Auto mode tries the approved HeyGen voice first, then a selected ElevenLabs voice after a confirmed rejection. It never blindly repeats a speech request with an unknown outcome.
- ElevenLabs uses the documented `/v1/text-to-speech/{voice_id}/with-timestamps` response. Word boundaries come from returned character intervals, not estimated reading speed.
- Removed the Google Translate fallback that silently replaced the selected voice and estimated word timings. Removed proportional scene timing and the ability to silently drop requested captions.
- Restored source-grounded scene validation. A short source range may extend forward by up to two seconds when matching footage is available. A scene is never relocated to the end of the video or shortened under its narration. A duration preset is no longer silently overridden.
- The owner sees the actual saved worker failure on the task page. Shared pages retain their generic failure text.
- Added a read-only narration allowance check before uploading/analyzing a new Roblox source. Confirmed empty wallets/quotas produce an actionable error before frame analysis; provider-scoped keys without account-read permission remain usable.
- Repaired provider/key/model pairing and added configured Google Gemini credentials as a fallback. Free OpenRouter vision choices are retained, with bounded attempts. Hidden model reasoning is never treated as a final scene plan. Provider refusals stop fallback.
- Added Economy/Balanced/Detailed visual analysis. Detailed mode samples more frames and rechecks selected shot/hit/flight contacts. Uncertain contacts are omitted; this is visual sampling, not a guarantee of frame-perfect action recognition.
- Produces separate speech/SFX sources, a float WAV mix master, complete SRT captions, ASS caption source, a scene/source map and final MP4. Music ducks under narration; final mixing targets about -16 LUFS and -1.5 dBTP.
- Existing regular long-video clipping, timed live capture, batch targeting up to 30 clips and optional Buffer scheduling remain separate from the Roblox mode. Their external-service end-to-end checks remain outstanding.

## ElevenLabs setup

Add locally to the existing project `.env`:

```env
ELEVENLABS_API_KEY=your_key_here
ELEVENLABS_MODEL_ID=eleven_multilingual_v2
```

An optional `ELEVENLABS_VOICE_ID` selects a server default. Otherwise choose **ElevenLabs**, click **Browse ElevenLabs voices**, listen to a preview and select a voice in the app. These are synthesis operations only; no voice cloning is performed. API allowance is separate from ChatGPT and from the other providers.

References: [ElevenLabs timed speech](https://elevenlabs.io/docs/api-reference/text-to-speech/convert-with-timestamps), [voice catalog](https://elevenlabs.io/docs/api-reference/voices/search), [subscription allowance](https://elevenlabs.io/docs/api-reference/user/subscription/get), [Gemini OpenAI compatibility](https://ai.google.dev/gemini-api/docs/openai).

## Activate and diagnose

After existing tasks finish, run in Command Prompt:

```cmd
cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
powershell -ExecutionPolicy Bypass -File ".\scripts\creator-diagnostics.ps1" -Rebuild
```

The helper checks that tasks and worker jobs are idle, validates Compose, rebuilds backend/worker/frontend, and writes redacted logs to `creator-diagnostics.txt`. It does not delete or recreate database/media volumes, queue a new video, or publish anything. Without `-Rebuild`, it only collects diagnostics.

Refresh the app with Ctrl+F5. Test one short Roblox build with Buffer disabled; preview it before enabling publication. A configured API key is not a guarantee of funds or available quota. Free provider capacity is also not guaranteed. Existing failed tasks keep their saved plans; corrections can be made in the scene editor.

## What has and has not been verified

43 focused creator tests, 3 existing Buffer adapter tests and 5 music tests passed. The focused creator regression suite covers mode/source validation, source/scene bounds, real character/word alignment, provider pairing/fallback, uncertain-generation protection, cached speech reuse, empty-account preflight, audio placement/headroom, a real FFmpeg video export, and Buffer scheduling spacing/partial failure/duplicate protection. Python and Compose syntax and isolated strict typing for the new controls were checked.

A 30-second MP4 preview was rendered from the previously prepared Iron Man footage and the exact previously accepted narration. Encoded audio measured -15.90 LUFS integrated and -1.51 dB true peak; full decode passed. Representative frames and the Forge GUI ending were visually checked. This preview reuses known editorial decisions and speech; it does not demonstrate a fresh vision analysis or a fresh ElevenLabs generation. Audible quality was not auditioned by the agent.

The local app was unreachable from this session, and Docker Desktop denied its named-pipe connection. Full frontend dependency installation/build was blocked by Windows filesystem errors. Full database/worker integration, image-security scanning, a real live capture, real Buffer publication, and fresh ElevenLabs speech have not been verified. The last account checks showed no purchased OpenRouter credits, a zero HeyGen wallet balance, and no ElevenLabs key. No new paid generation or posts were sent during this repair. Those external conditions must be resolved or satisfied by an eligible provider allowance before calling the complete product live-verified.
