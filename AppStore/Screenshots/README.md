# Screenshot specification

Use JPEG or PNG files without transparency in one of Apple's accepted 16:10
macOS sizes. The 1.0 assets use 1280 × 800.

Prepared 1.0 sequence:

1. `01-reading-window-1280x800.jpg` — bundled `Sample.md` rendered with
   Contents, Mermaid, and Live/Read Only status
2. `02-side-by-side-1280x800.jpg` — two `Sample.md`-based documents in
   independent, arranged windows, with Contents shown on one side and hidden
   on the other

The 1.0 screenshots use only the public bundled sample and contain no private
document content. Image files remain ignored by Git so store-specific artwork
can be replaced without changing the source tree. Keep the filenames stable
locally so replacement screenshots are easy to review and upload to App Store
Connect.
