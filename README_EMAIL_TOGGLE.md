# SupoClip optional email notifications patch

This patch makes email notifications optional. It does not replace your `.env` file or change Buffer/B2 credentials.

## Apply
1. Extract this ZIP.
2. Copy the contents of the included `supoclip-main` folder into your existing `C:\Users\Tejas Bhavsar\supoclip-main` folder, preserving the folder paths and allowing these code files to be replaced.
3. Do **not** overwrite `.env`. Keep your existing real credentials.
4. In your existing `.env`, use `POST_PUBLISH_EMAIL_ENABLED=false` to turn email off, or `POST_PUBLISH_EMAIL_ENABLED=true` to turn it on.
5. Run from CMD in the project folder: `docker compose up -d --build backend frontend worker`.
6. Check `docker compose ps` and wait for backend and worker to become healthy.

## Behavior
- `false`: the email sender skips notifications without SMTP validation, email does not block Buffer scheduling, and the UI shows notifications as OFF. A test email cannot be sent while disabled.
- `true`: real SMTP credentials and `POST_PUBLISH_NOTIFICATION_EMAIL` recipients must be configured. The UI offers a test-email action and reports configuration problems.
- Toggle changes in `.env` require rebuilding/restarting the services above.

This patch is prepared against the code layout from the SupoClip private Backblaze signed-URL patch. Test with a single Reel before scheduling a full batch.
