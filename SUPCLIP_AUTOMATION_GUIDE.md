# SupoClip: clip selection and publishing automation

This patch adds controls and an optional batch workflow to the existing SupoClip project.

## What's added

- **Clip-count target:** choose 1, 3, 5, 8, or 10 clips before generation. The AI is asked for that many distinct, valid moments, but the final count can be lower if the source does not contain enough suitable segments or a configured processing limit is lower.
- **Caption position:** choose top, middle, or bottom when starting a job. The selection is saved with task metadata and passed to caption rendering, including resumed jobs.
- **AI post metadata:** generates a title, a short description/caption, and 3–8 hashtags through the same configured LLM as clip analysis. This removes the previous extra requirement for an Anthropic key specifically for this social-caption step.
- **Schedule All:** on a completed task, when social publishing and scheduling are enabled and a supported account is connected, the task page offers a batch scheduler. It generates metadata for each clip and creates a scheduled post for each one using a configurable first time, interval, visibility, and connected destination account.
- **Existing publishing queue:** batch-scheduled posts use SupoClip's existing social publishing records and worker. Do not expect social publishing to work until you have configured and connected the destination platform.

## Apply to an existing Windows Docker installation

1. Back up the current project folder. Keep your existing `.env` file and API keys private.
2. For the smaller update patch, extract its contents directly into your existing `supoclip-main` folder and choose **replace files** when Windows asks. The patch does not contain `.env`, so your API keys file is not overwritten. Alternatively, extract the full enhanced project ZIP and copy its contents into the existing folder. Do not overwrite `.env` with `.env.example`.
3. From CMD, enter the project directory:

   ```cmd
   cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
   ```

4. Run the included Windows helper from CMD:

   ```cmd
   enable-selfhost-features.cmd
   ```

   It updates only the self-host feature switches/limits in `.env` and recreates the frontend, backend, and worker. It does not rebuild the large images or touch persistent volumes. If you prefer to edit `.env` manually, use the values in the next section and then run `docker compose up -d --force-recreate backend worker frontend`.

5. Check status and logs:

   ```cmd
   docker compose ps
   docker compose logs --tail=100 backend worker frontend
   ```

6. Refresh `http://localhost:3107` with `Ctrl+F5`. Existing task and uploaded-media volumes should be retained if you continue using the same Compose project and do not remove volumes.

## Unlock the self-hosted feature set

The self-hosted app does not need a Pro/Creator subscription. It already bypasses hosted monthly-minute billing and 720p output caps. This patch additionally uses a 3-hour source-video default and turns on the self-host social-publishing UI/access by default. The local landing page hides the hosted paid-plan pricing section when `NEXT_PUBLIC_SELF_HOST=true`; this changes only your local self-hosted copy, not the public SupoClip website.

On Windows, run `enable-selfhost-features.cmd` from the project folder. It updates these keys in your existing `.env` without overwriting other API keys or app secrets, then recreates the frontend, backend, and worker containers. It does not delete database, upload, or clip volumes.

The important settings are:

```dotenv
SELF_HOST=true
MAX_VIDEO_DURATION=10800
SOCIAL_PUBLISHING_ACCESS=all
SOCIAL_PUBLISHING_PROVIDERS=youtube,tiktok,instagram
```

The video duration value is seconds: `10800` = 180 minutes. This is a configurable technical limit; processing very long videos still depends on disk space, RAM, CPU/GPU capacity, download provider limits, and transcription time.

### Paid-plan feature audit for self-hosting

- **Monthly minutes / usage quota:** no hosted subscription quota in self-host mode.
- **720p vs 1080p:** self-host exports are not downscaled by the hosted Pro-plan cap.
- **Three-hour source videos:** the self-host default is 180 minutes, subject to download/transcription/provider/hardware limits.
- **Custom fonts, caption templates, export presets, face-centered cropping and virality scoring:** these are code features and do not need a hosted Pro/Creator subscription.
- **B-roll:** the feature is present, but Pexels-sourced footage needs your own `PEXELS_API_KEY` and remains subject to that provider's terms/limits.
- **Social publishing and batch scheduling:** the local access switch is enabled, but each destination still requires its own OAuth app credentials, user authorization, API permissions and platform approval.
- **Priority processing:** this is a hosted infrastructure advantage, not a software entitlement that can make a local PC faster. Local queue throughput is limited by your own hardware and worker capacity.

The local pricing/upgrade marketing section is hidden in the self-hosted frontend build only. Visiting the public `supoclip.com` website does not change its hosted subscription pricing.

## Connect accounts for automatic posting

Unlocking the UI does not create platform credentials. To publish automatically, create your own platform developer apps and fill in the relevant values in `.env`:

```dotenv
YOUTUBE_OAUTH_CLIENT_ID=your_google_oauth_client_id
YOUTUBE_OAUTH_CLIENT_SECRET=your_google_oauth_client_secret
SOCIAL_OAUTH_REDIRECT_BASE_URL=http://localhost:3107
TIKTOK_CLIENT_KEY=
TIKTOK_CLIENT_SECRET=
INSTAGRAM_APP_ID=
INSTAGRAM_APP_SECRET=
```

For YouTube, enable the YouTube Data API and register the exact callback/redirect URI requested by the app. Sign into SupoClip, connect YouTube in **Settings → Social**, open a completed task, and use **Schedule all N**. Each clip gets generated title, description/caption, hashtags, and its own scheduled time.

TikTok and Instagram require their own app credentials, the required API permissions and any platform review/approval. Instagram publishing generally needs a publicly reachable HTTPS media URL, so a localhost-only installation is not enough for every provider. External platforms can also impose upload, account, and content rules.

## Important runtime limitations

- The scheduler runs in the project's background worker. On a local PC, Windows, Docker Desktop, network, and the containers must remain running for due posts to publish on time. Use an always-on host for dependable 24/7 automation.
- Platform OAuth permissions, upload limits, content rules, and API review status still apply. Successful scheduling means a post is queued for the requested time; it cannot guarantee a platform will accept or publish every item.
- AI-generated titles, captions, and hashtags must be reviewed for accuracy. The configured LLM provider may charge for generation.
- The clip-count setting is a target, not a guarantee of exactly N clips. Clips must be valid, distinct, and within the project's configured limits.
- Full automated tests and frontend type-check/build could not be run in this environment because project dependencies are not installed and network access to the package registry was unavailable. Run `docker compose logs --tail=100 backend worker frontend` if something fails after applying the patch.
