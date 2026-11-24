# SupoClip — consolidated Buffer auto-posting fix (Backblaze B2 public MP4 URLs)

This patch uses your existing Backblaze B2 bucket as stable object storage. SupoClip uploads each rendered MP4 with the S3 API, then validates the public direct MP4 URL (HTTP HEAD, `video/mp4`, exact length, and a one-byte range request) before submitting it to Buffer. It does not send the video through the temporary Cloudflare tunnel.

Email is optional and off by default. The patch does not contain or overwrite `.env`, clips, uploads, or database contents.

## One-time Backblaze setup

1. In Backblaze B2, open bucket `supoclip-buffer-media` and change its bucket access to **Public**. This makes objects readable to anyone who has the URL. Do not store confidential clips in this bucket.
2. Keep using the existing bucket-scoped application key with write access to this bucket. Do not paste credentials into chat or commit them.
3. For region `us-east-005`, the direct download base is `https://f005.backblazeb2.com/file/supoclip-buffer-media`. If Backblaze's bucket page shows a different download host, use the exact host it displays.
4. In the existing root `.env`, update these existing values (do not add duplicates):

```dotenv
BUFFER_MEDIA_PUBLIC_BASE_URL=https://f005.backblazeb2.com/file/supoclip-buffer-media
BUFFER_MEDIA_S3_BUCKET=supoclip-buffer-media
BUFFER_MEDIA_S3_ENDPOINT=https://s3.us-east-005.backblazeb2.com
BUFFER_MEDIA_S3_REGION=us-east-005
BUFFER_MEDIA_S3_ACCESS_KEY_ID=YOUR_EXISTING_B2_APPLICATION_KEY_ID
BUFFER_MEDIA_S3_SECRET_ACCESS_KEY=YOUR_EXISTING_B2_APPLICATION_KEY
BUFFER_MEDIA_S3_PREFIX=supoclip-buffer
POST_PUBLISH_EMAIL_ENABLED=false
```

Use your existing actual key values locally; never replace them with the words `YOUR_EXISTING...`. Keep `MEDIA_STORAGE=local` if that is what your app currently uses—the Buffer host uploads a separate copy. Leave `SOCIAL_PUBLIC_MEDIA_BASE_URL` and the Cloudflare tunnel out of the Buffer media path.

## Apply the patch (single installation sequence)

1. Close any editor that is changing project files. Make a backup copy of the whole project folder first.
2. Extract this ZIP into `C:\Users\Tejas Bhavsar\supoclip-main` and choose **Replace files** for the included patch files. **Do not replace or edit `.env` from the ZIP**; this patch deliberately does not contain it.
3. Open CMD and run this complete sequence:

```cmd
cd /d "C:\Users\Tejas Bhavsar\supoclip-main"
docker compose config --quiet
docker compose build --no-cache backend worker frontend
docker compose up -d backend worker frontend
docker compose ps
docker compose logs --tail=100 backend worker
```

The no-cache rebuild is intentional: the backend and worker images must contain the `boto3`/`botocore` dependencies already declared by the backend project. It also avoids reusing the older image that reported `No module named 'boto3'`. If the build itself fails, do not schedule posts; the build output will identify the dependency or source issue.

## Confirm setup and schedule

1. Wait for backend, worker, frontend, PostgreSQL, and Redis to show running/healthy.
2. Open `http://localhost:3107`, refresh with `Ctrl+F5`, open a completed task, and choose **Schedule via Buffer**.
3. The setup checklist must show Buffer API and direct public MP4 hosting configured. Email should say disabled/optional.
4. Schedule **one Reel** a few minutes in the future. Confirm it appears in the Buffer queue before scheduling a batch.
5. If upload/public URL validation fails, SupoClip stops before submitting to Buffer and shows the specific failing check. Do not repeatedly submit the same Reel until the media URL passes validation.

## Important

- Public bucket URLs are bearer links. Anyone who obtains one can view that MP4.
- Backblaze lifecycle rules should retain objects beyond the furthest scheduled publication date; this integration schedules only after a successful public URL preflight.
- A successful Buffer queue submission is not the same as a confirmed Instagram publication. Check the first scheduled Reel before relying on unattended batches.
- The ZIP does not include credentials, `.env`, database data, uploads, or generated clips.
