---
description: Cut a sahha_flutter release — bump version + native iOS/Android SDK refs, changelog, commit, PR, tag, publish to pub.dev
argument-hint: <version> e.g. 1.3.9-beta.5 (optionally <native-sdk-version> if it differs)
---

You are cutting a release of the `sahha_flutter` package.

Target package version: **$1**. Native iOS `Sahha` pod + Android `sahha-api` version: **$2** if provided, otherwise default to **$1** (they normally match the package version).

If `$1` is empty, ask the user for the target version before doing anything. Do NOT add Claude attribution to any commit or PR (no `Co-Authored-By` trailer, no "Generated with Claude Code" footer).

Work through the flow below, confirming irreversible/outward steps with the user as noted.

## 1. Pre-flight
- `git status` and `git branch --show-current`. Release work happens on `development`; if not there, switch to it and pull. Reconcile any in-progress version edits already in the working tree (e.g. a partial bump) toward the target version.
- Note the previous version (current `version:` in `pubspec.yaml`) and confirm the target ($1) and native SDK version ($2 or $1) with the user.

## 2. Bump version + native SDK references
Replace the old version with the targets:
- `pubspec.yaml` → `version: $1`
- `ios/sahha_flutter.podspec` → `s.version = '$1'`
- `ios/sahha_flutter.podspec` → `s.dependency 'Sahha', '<native version>'`  ← iOS SDK ref
- `android/build.gradle` → `implementation "ai.sahha.android:sahha-api:<native version>"`  ← Android SDK ref

Then grep the repo for any stray old-version strings to be sure none were missed (exclude historical CHANGELOG entries).

## 3. CHANGELOG.md
Prepend a new entry (Keep a Changelog style — always keep all three headings, even if empty):

```
## $1

### Added

-

### Changed

- Updated IOS to <native version> check release notes https://github.com/sahha-ai/sahha-ios/releases
- Updated Android to <native version> check release notes https://github.com/sahha-ai/sahha-android-sdk/releases

### Fixed

- <fixes, or `-` if none>
```

Ask the user what goes under Added / Fixed.

## 4. Keep local test edits OUT of the commit
Never commit these local-only test changes:
- `example/lib/Views/AuthenticationView.dart` — gets hardcoded `appId`/`appSecret` during testing. Verify empty defaults; exclude if modified.
- `example/ios/Runner.xcodeproj/project.pbxproj` — gets a local `DEVELOPMENT_TEAM`. Exclude.

Stage release files explicitly (do NOT `git add -A`): `pubspec.yaml`, `ios/sahha_flutter.podspec`, `android/build.gradle`, `CHANGELOG.md`, any real code/doc changes (e.g. `android/.../SahhaFlutterPlugin.kt`, `README.md`), and the regenerated `example/ios/Podfile.lock` + `example/pubspec.lock` if the SDK bump changed them. Show staged vs unstaged and confirm only the right files are staged.

## 5. Commit on development
Commit message `fix: update to $1` (plus a short body for any real fix). NO Claude attribution.

## 6. Push + PR (protected-branch handoff)
A git guardrail blocks Claude from pushing/force-pushing `main` and `development`, so:
- Ask the USER to run `git push origin development` (use `git push --force-with-lease origin development` if you amended an already-pushed commit).
- After it's pushed, open the PR: `gh pr create --base main --head development --title "fix: update to $1" --body-file <tmpfile>` with a body in Added/Changed/Fixed format. NO Claude attribution. Verify the body has no attribution.
- Ask the user to merge the PR into `main`.

## 7. Tag (after merge)
- `git fetch`, then confirm the `fix: update to $1` release commit is on `origin/main`.
- Create an annotated tag on that RELEASE commit (NOT the merge commit) so it's reachable from both branches: `git tag -a $1 <release-commit-sha> -m "$1"`.
- Push the tag (allowed for Claude): `git push origin $1`. Verify with `git ls-remote --tags origin $1`.

## 8. Publish to pub.dev
- Ensure a clean working tree equal to the tagged commit.
- Validate: `flutter pub publish --dry-run` (expect 0 warnings). Confirm no secrets in the archive (especially `AuthenticationView.dart`) and that pub.dev credentials exist (`~/Library/Application Support/dart/pub-credentials.json`).
- pub.dev publish is IRREVERSIBLE (retract only within 7 days, version never reusable). Get explicit user confirmation, then run `flutter pub publish --force`.
- Betas publish as prereleases (stable stays "latest").

## 9. GitHub Release (stable only)
- For a STABLE `x.y.z`: create a GitHub Release — `gh release create $1 --title "$1" --notes "<this version's changelog section>"`.
- For a beta/prerelease: skip the GitHub Release (this repo only cuts GitHub Releases for stable versions).

## 10. Wrap up
- Summarize what shipped + the pub.dev URL (`https://pub.dev/packages/sahha_flutter/versions/$1`).
- Note that `development` is now behind `main` by the merge commit; offer to fast-forward `development` to `main` (the USER runs the push).
