# Photo Manager App Design (macOS, keeps originals in place)

## Goals
- Never duplicate photos; reference originals via paths/bookmarks.
- Tolerate file moves/renames and reconnect automatically.
- Fast browsing with thumbnails and metadata filters.
- AI-assisted tagging, captions, and semantic search.
- Respect privacy/cost controls (local-only or cloud AI).

## Platform & Stack
- SwiftUI app, macOS 14+, sandboxed.
- Persistence: Core Data (or SQLite/GRDB) storing file records, bookmarks, metadata, AI outputs, embeddings.
- Thumbnails/previews: cached in `Application Support` under app container.
- File coordination: `NSFileCoordinator`/`NSFilePresenter`; security-scoped bookmarks for user-selected files/folders.
- File events: FSEvents on watched roots to detect moves/renames; Spotlight queries as fallback.

## Data Model (Core Entities)
- `Asset`: id, security-scoped bookmark, resolvedURL cache, quick hash (xxHash) + slow hash (SHA-256), filename, file type/UTI, file size, created/added dates, EXIF date, camera/lens, orientation, dimensions, rating/flag, offline/missing status.
- `Keywords`: user keywords (many-to-many with Asset).
- `AITags`: provider, labels, caption, confidence, timestamp.
- `Embedding`: provider, vector (e.g., 512-D), reduced index data for search.
- `Album` and `SmartAlbum`: static membership vs rule-based filters.
- `TaskState`: background job queue persistence (thumbnail, EXIF, AI tagging, hash, resolve).

## Import Flow (No Copies)
1) User selects files/folders (NSOpenPanel with security scope) → create bookmarks.
2) Resolve initial URL, read basic file stats; store quick hash for dedupe.
3) Enqueue:
   - EXIF read (capture date, camera, GPS if present).
   - Thumbnail generation (max size cache).
   - Full hash (for move/Spotlight fallback).
4) Optional: configure “watched folders” to auto-import new files.

## Tracking Moves/Renames
- Primary: resolve security-scoped bookmark before access; update stored path if different.
- Secondary: FSEvents watcher for selected roots; if file moved, update `resolvedURL`.
- Fallback: if bookmark resolution fails, search Spotlight by content hash/EXIF tuple; if found, rebind bookmark.
- Mark assets as `missing` when unresolved; retry periodically and on app launch.

## AI Tagging & Providers
- Cloud options: OpenAI (gpt-4o-mini/gpt-4o) for captions + keywords; Azure Vision/Google Vision alternatives with provider abstraction.
- Local/on-device: Core ML (e.g., BLIP/CLIP converted to Core ML) for captions + embeddings; Apple Vision for object/scene labels and face detection (no network).
- Per-asset AI cache: labels, caption, confidence, timestamp; per-provider to avoid reprocessing.
- Cost/privacy: per-folder opt-in for cloud, daily spend cap, “local-only” mode toggle.

## Search & Filtering
- Text search across filename, user keywords, AI captions/labels.
- Filter by date ranges, rating/flag, camera/lens, people/faces, file type, folder, missing/offline state, “Needs AI tags”.
- Semantic search: cosine similarity over embeddings (sqlite-vss or sidecar vector index); toggle between keyword and semantic.
- Smart albums: rules over metadata/AI tags (e.g., “Screenshots this week”, “Photos with Cat label and rating ≥ 3”).

## UI Sketch (SwiftUI)
- Sidebar: albums/smart albums, watched folders, “Missing”, “Needs AI tags”, “Offline”.
- Top bar: search field with keyword/semantic toggle; quick filters (faces, documents, screenshots).
- Main grid: adaptive thumbnails, badges for offline/missing/AI pending; sort by date/name/rating.
- Detail pane: large preview, EXIF/metadata, edit keywords, AI tags with enable/disable, open/reveal in Finder, breadcrumb to folder.
- Background activity indicator for import/AI queues.

## Background Pipelines
- Operation/Swift concurrency queues with persisted `TaskState`.
- Stages: bookmark resolve → quick hash → EXIF → thumbnail → full hash → AI tagging/embeddings → face detection.
- Throttle AI calls; batch cloud requests where possible; resume queued work on relaunch.

## Privacy & Resilience
- Security-scoped bookmarks for all user-selected paths; prompt scope renewal when needed.
- Local-only mode keeps AI fully on-device; cloud mode guarded by per-provider caps.
- Handle offline volumes: mark assets offline; skip heavy work until volume online.
- Backup: allow export/import of database plus bookmark data; avoid storing user photos.

## Next Steps
- Choose provider strategy (cloud vs local) and vector indexing approach.
- Define Core Data/SQLite schema from entities above.
- Build shell UI (sidebar/grid/detail) with mock data.
- Implement import + bookmark resolve pipeline; add missing/offline handling.
- Add thumbnail/EXIF workers, then first AI tagger + semantic search toggle.
