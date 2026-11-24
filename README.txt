SupoClip Buffer media HEAD-request fix

Files in this patch:
  backend/src/api/routes/social.py
  frontend/src/app/api/social/buffer-media/[token]/route.ts

What changed:
- Backend: GET and HEAD share token/path validation. The backend now has an
  explicit HEAD endpoint that returns FileResponse headers without transferring
  the video body.
- Frontend: HEAD now forwards a real HEAD request to the backend instead of
  calling GET and cancelling the streamed response. GET continues streaming.

Important:
- Back up the matching files in your repo before replacing them.
- The backend file was built from the full social.py source pasted in this chat.
- This addresses the observed HEAD timeout; it cannot guarantee Buffer will
  accept the media URL until a new test is run.
- Keep the Cloudflare tunnel running while testing. Quick Tunnel URLs are
  temporary and may change after a restart.

From the repo root, after replacing files, rebuild/restart the affected services:
  docker compose up -d --build backend frontend worker

Then test local HEAD:
  curl.exe -I --max-time 15 "http://localhost:3107/api/social/buffer-media/<TOKEN>"

Expected: quick HTTP 200 response with Content-Type: video/mp4 and Content-Length
matching the file. Replace <TOKEN> with the real token currently being tested.
