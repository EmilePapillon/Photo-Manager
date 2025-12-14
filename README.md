# Photo Manager (prototype)

SwiftUI macOS 14+ app that indexes photos in-place using bookmarks, background tasks, and AI-assisted tags/search. This repo currently ships a UI shell with mock data; storage, import, AI, and thumbnail pipelines are stubbed for future implementation.

## Requirements
- macOS 14+
- Xcode 15+ (or Swift 5.9 toolchain)

## Build & Run (Swift Package Manager)
1. From the repo root, build: `swift build`
2. Run the app: `swift run PhotoManager`

If you prefer Xcode, open the package: `xed .` then press Run.

> Note: In restricted environments, SwiftPM may need access to `~/Library/org.swift.swiftpm` and `~/.cache/clang` for build caches. If you hit permission errors, rerun with normal user permissions outside a sandbox.

## Project Layout
- `Package.swift` – SwiftPM manifest targeting macOS 14.
- `Sources/PhotoManager` – app entry (`PhotoManagerApp`), models, view models, and SwiftUI views.
- `Sources/PhotoManager/Resources` – placeholder for assets (thumbnails, etc.).

## Status
UI shell with mock data is implemented; Core Data persistence, import pipeline, AI providers, and thumbnail/EXIF workers remain to be wired. See `DESIGN.md` for the full plan.
