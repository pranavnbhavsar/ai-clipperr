# SupoClip — Full Updated Project and Buffer Auto-Posting Setup

This package combines the SupoClip source tree with the consolidated Buffer direct-public-MP4 hosting changes. It intentionally contains **no `.env` file**, real API keys, database volume, uploads, generated clips, or Python bytecode caches. When extracting over your existing project, your current `.env` is not overwritten.

## What changed

- Direct object storage for each Buffer Reel using Backblaze B2's S3-compatible endpoint.
- Public MP4 URL preflight before the Buffer API is called: checks HTTP HEAD, `video/mp4`, exact file length, and a one-byte range request.
- Buffer readiness status reports direct public media hosting instead of treating a temporary Cloudflare tunnel as durable storage.
- Email notifications are optional and disabled by default (`POST_PUBLISH_EMAIL_ENABLED=false`).
- Batch scheduler UI reflects the media-hosting readiness and no longer blocks scheduling merely because SMTP is not configured.
- Existing application source, self-host settings, clip-count updates, migrations, and frontend/backend project files are retained from the supplied full source archive.

## One-time Backblaze setup

1. In Backblaze B2, open bucket `supoclip-buffer-media` and set bucket access to **Public**. This makes each object's URL readable to anyone who obtains it. Do not use this bucket for confidential video.
2. Use a bucket-scoped application key with sufficient permissions to upload and read/list objects for this bucket. Keep its Key ID and Application Key private.
3. For region `us-east-005`, the direct download base is `https://f005.backblazeb2.com/file/supoclip-buffer-media`. Confirm the download hostname shown in your Backblaze console; use that if it differs.
4. Edit your existing root `.env` locally and update the following keys. **Use your real existing key values in your local file; never replace your whole `.env` with `.env.example`.**

```dotenv
BUFFER_MEDIA_PUBLIC_BASE_URL=https://f005.backblazeb2.com/file/supoclip-buffer-media
BUFFER_MEDIA_S3_BUCKET=supoclip-buffer-media
BUFFER_MEDIA_S3_ENDPOINT=https://s3.us-east-005.backblazeb2.com
BUFFER_MEDIA_S3_REGION=us-east-005
BUFFER_MEDIA_S3_ACCESS_KEY_ID=YOUR_EXISTING_B2_KEY_ID
BUFFER_MEDIA_S3_SECRET_ACCESS_KEY=YOUR_EXISTING_B2_APPLICATION_KEY
BUFFER_MEDIA_S3_PREFIX=supoclip-buffer
POST_PUBLISH_EMAIL_ENABLED=false
```

Replace both key placeholders locally with your existing B2 credentials. Do not paste them into chat or commit them. Keep `MEDIA_STORAGE=local` if that is already the current setting; Buffer media is uploaded separately. The Buffer workflow should no longer depend on `SOCIAL_PUBLIC_MEDIA_BASE_URL` or a temporary `trycloudflare.com` hostname.

## Install the full project in one sequence

1. Close editors that may be writing to the project folder.
2. Back up `C:\Users\Tejas Bhavsar\supoclip-main` as a normal folder copy. Keep the current `.env` and database volumes.
3. Extract this ZIP into `C:\Users\Tejas Bhavsar\supoclip-main` and choose **Replace files** if Windows prompts. Since the ZIP intentionally omits `.env`, it will not replace your local settings.
4. Open Command Prompt and run this sequence:

```cmd
cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
docker compose config --quiet
docker compose build --no-cache backend worker frontend
docker compose up -d backend worker frontend
docker compose ps
docker compose logs --tail=100 backend worker
```

The no-cache rebuild is intentional because the previous backend runtime reported `No module named 'boto3'`; the project declares `boto3` in its backend dependency configuration. This ensures the backend/worker images are rebuilt rather than reusing the stale image. Do **not** run `docker compose down -v` and do not delete the database volumes.

## Final validation

1. Wait until backend, worker, frontend, PostgreSQL, and Redis are running/healthy.
2. Open `http://localhost:3107` and press `Ctrl+F5`.
3. Open a completed task and select **Schedule via Buffer**. Ensure Buffer API and direct public MP4 hosting show as configured. Email should be shown as disabled/optional.
4. Schedule **one Reel** a few minutes in the future. Confirm it appears in the Buffer queue and verify that Instagram actually publishes it before scheduling the larger batch.

If SupoClip stops at media preflight, read the exact response and backend log. It should stop before contacting Buffer when the public URL cannot be verified. Do not repeatedly resubmit a Reel until the preflight passes.

## Security and operational notes

- The base archive provided for this build contained a real `.env`; that file is deliberately excluded from this final ZIP. Rotate any API keys that were included in a shared/uploaded archive, then update your local `.env`.
- Keep your Backblaze key private and bucket-scoped. Public bucket access affects video URLs, not access to the S3 credentials.
- A successful Buffer queue submission is not proof that Instagram published the Reel. Verify the first scheduled Reel before relying on unattended batches.
- The base includes application code and migrations, not your live database contents or uploaded media. Existing Docker volumes are preserved by the installation commands above.
