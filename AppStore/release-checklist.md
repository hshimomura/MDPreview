# Public release checklist

This checklist covers reproducible source, metadata, and build verification.
It intentionally excludes App Store Connect review workflow and account
operations.

## Source and licenses

- [ ] Confirm the release tag points to the intended source commit.
- [ ] Run `swift test`.
- [ ] Review `Package.resolved` and `swift package show-dependencies`.
- [ ] Verify `THIRD_PARTY_NOTICES.md` and bundled license texts.
- [ ] Confirm the app remains read-only and does not transmit documents.

## Public App Store material

- [ ] Run `./Scripts/verify-app-store-metadata.sh`.
- [ ] Review English and Japanese product-page text.
- [ ] Verify the Marketing, Support, and Privacy Policy URLs.
- [ ] Use only public `Sample.md` content in screenshots.
- [ ] Confirm no review status, contact details, submission identifiers, or
      private documents are tracked.

## Build

- [ ] Run `./Scripts/generate-xcode-project.sh`.
- [ ] Archive the `MDPreview` scheme for Any Mac.
- [ ] Export the Mac App Store package.
- [ ] Run `./Scripts/verify-app-store-export.sh`.
- [ ] Record source and release checksums with the GitHub Release.

App Store Connect remains the source of truth for upload, review, availability,
pricing, and release state.
