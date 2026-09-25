# 1.4.0-beta.3 field test plan and example-app Stress Lab

On-device validation of the `sahha-ios` 1.4.0-beta.3 remediation (PRD sahha-ai/sahha-ios#76,
children #77–#89), driven from this repo's Flutter example app running against a **local**
`sahha-ios` checkout, with the HealthKit Data Generator seeding realistic and adversarial data.

Two deliverables:

1. **Stress Lab** — new debug-only screen plus a native chaos channel in the example app's
   Runner, so a device can be put into the exact broken states the remediation fixes.
2. **Scenario scripts** — the runbook below, executed on a physical iPhone.

## Constraints

- **Nothing test-only ships in the plugin.** All sabotage lives in the example app's own iOS
  Runner behind `#if DEBUG`. `lib/sahha_flutter.dart`, `ios/Classes/**` and the podspec are
  not touched by this work.
- **Sabotage only public surfaces** the SDK genuinely reads: `UserDefaults` keys, keychain
  items, and app-wide HealthKit APIs. Never reach into SDK internals — the tests must stay
  honest about states a real device can actually reach.
- Both repos are public. No customer identifiers (names, external IDs, profile IDs) in any
  committed file. Profile IDs read at runtime on-device are fine; they must never be written
  into the repo.
- No AI attribution anywhere in commits, PRs, or code comments.

## 1. Wiring the local SDK

1. In `sahha-ios`: `git checkout development && git pull`. The remediation PRs (#77–#88) are
   merged there. The still-open PR #103 is docs/release-script only and does not affect
   device behaviour.
2. In `example/ios/Podfile` the override already exists, commented out — uncomment it:

   ```ruby
   pod 'Sahha', :path => '../../../sahha-ios/'
   ```

   `ios/sahha_flutter.podspec` pins `'Sahha', '1.4.0-beta.2'` and the local podspec currently
   declares exactly that, so the pin resolves. (When `release.sh` bumps the SDK podspec to
   beta.3, this plugin's pin needs the same bump — a normal wrapper release step, not a
   testing concern.)
3. `flutter pub get` in `example/`, then `pod install` in `example/ios/`. Proof it took: the
   install log says `Installing Sahha 1.4.0-beta.2` and `Podfile.lock` lists Sahha under
   `EXTERNAL SOURCES` with the `:path`. The Stress Lab inspector re-checks at runtime.
4. A path pod references the SDK sources in place, so edits in `sahha-ios` are picked up on
   the next build with no `pod install` — that is only needed when files are added or removed
   or the podspec changes.
5. **Turn on the SDK's console narration.** `Sahha.debugLogging` (`Sahha.swift:58`) is
   internal and defaults to `false`. For the test run, flip that default to `true` in the
   local `sahha-ios` working copy — an uncommitted, local-only tweak. It unlocks ~115
   narration lines across every subsystem under test: `[SahhaActor]` (bring-up deferrals),
   `[Network Monitor]`, `[SensorHealthCheck]`, `[HealthKitObserver]`, `[Background Upload]`,
   `[Circuit Breaker]`, `[PostSensorData]`.
6. `flutter run -d <device>` keeps narration in the terminal. For background-delivery
   scenarios where `flutter attach` dies, run the `Runner` scheme from Xcode instead — its
   console survives backgrounding, and Console.app (filter: process `Runner`) sees everything
   untethered once the build is on the phone.

### Device-state levers

- **Deleting the app is not a reset.** The keychain (service `ai.sahha.ios`) survives app
  deletion on iOS, so a reinstall can come up already authenticated. `deauthenticate` is the
  reliable profile reset — and that totality is itself under test (D2).
- **HealthKit permission state is one-way.** Once the sheet has been shown, the app can never
  return to "never asked". Run the permission-contract scenario (E4) **first**, on a freshly
  installed build, before anything else calls `enableSensors`.
- Generated samples can be removed with the generator's store cleaner, so volume runs do not
  permanently pollute the Health database.

## 2. Observation channels

Every scenario names where its pass signal appears:

- **In-app** — existing activity logs on the Permissions/Diagnostics screens, plus the new
  Stress Lab result cards and storage inspector.
- **Console** — `Sahha.log` narration (needs the debugLogging flip). The only place backoff
  timing, trigger firing and health-check verdicts are visible.
- **Dashboard error logs** — the remediation made formerly-swallowed failures visible, so
  several scenarios *expect* specific error logs. Section 6 inventories them; anything not on
  that list is a finding.
- **Dashboard data logs** — arrival of uploaded samples is the end-to-end pass signal. Use
  data logs, not scores/biomarkers: those are server-processed on a delay.

## 3. Stress Lab implementation spec

### 3.1 Native chaos channel

A `#if DEBUG` `MethodChannel` named `sahha_flutter_example/chaos`, registered in
`example/ios/Runner/AppDelegate.swift` after `GeneratedPluginRegistrant.register(with: self)`.
The Runner links the same Sahha pod and shares the app's UserDefaults and keychain, so it can
corrupt exactly what a broken upgrade would corrupt.

**Storage encodings** (verified against the SDK — match these exactly or the sabotage will
not reproduce the real states):

| Surface | Encoding |
| --- | --- |
| Sensor set | `UserDefaults.standard`, key `sensors`, value is `Data` holding a **JSON array of raw-value strings** (`JSONEncoder` on `Set<SahhaSensor>`) |
| HealthKit anchors | `UserDefaults.standard`, key prefixes `hkAnchor.` / `hkAnchorDate.`; pre-rename forms are `sahha_hkAnchor.` / `date_hkAnchorDate.` |
| Tokens | Keychain generic password, service `ai.sahha.ios`, account `token`, value is `Data` holding `JSONEncoder`-encoded `{"profileToken":String,"refreshToken":String,"expiresIn":Int,"tokenType":String}` |
| Demographic | Same service, account `demographic` |
| Device id | `UserDefaults.standard`, key `deviceId` — must **survive** deauthentication |

| Method | Behaviour | Scenario |
| --- | --- | --- |
| `poisonStoreLegacy` | Write `sensors` as JSON `["dietary_biotin","dietary_caffeine","dietary_fat_total","sleep","steps"]` (1.3.7-era names, from `SahhaSensor.legacyRenames`) | A1 |
| `poisonStoreMixed` | Write `["steps","sleep","not_a_sensor"]` | A2 |
| `poisonStoreAllUnknown` | Write `["from_the_future_a","from_the_future_b"]` (downgrade simulation) | A3 |
| `poisonStoreForeign` | Write a plain `String` (not `Data`) under the key | A4 |
| `poisonStoreGarbage` | Write 32 random bytes as `Data` | A5 |
| `relocateAnchorsToLegacyKeys` | Move every `hkAnchor.*` / `hkAnchorDate.*` default to its pre-rename key and delete the modern one | A6 |
| `disableAllHKBackgroundDelivery` | `HKHealthStore().disableAllBackgroundDelivery()` — the app-wide API, diverging real HK state from the SDK's belief exactly as an iOS update or restore does | C2 |
| `expireProfileToken` | Forge profile token as a well-formed JWT with **past `exp`**, keep the real refresh token | D5a |
| `invalidateProfileToken` | Forge profile token as a well-formed JWT with **future `exp`** and a bogus signature, keep the real refresh token | D5b |
| `expireRefreshToken` | Forge refresh token as a well-formed JWT with **past `exp`** | D6a |
| `invalidateBothTokens` | Both forged well-formed with future `exp` and bogus signatures | D6b |
| `inspectStorage` | Read-only report: `sensors` key (value type + decoded JSON), anchor-key counts by prefix (modern vs legacy), keychain item **presence only** (never contents), `deviceId` presence, and the loaded Sahha version from the framework bundle — runtime proof the local build is running | every verify step |

**Token forging rules — these are load-bearing.** `JWT.isExpired` returns `true` for anything
it cannot decode, and `AuthManager` gates on it in three places:

- `AuthManager.swift:73` — if the profile token is locally expired, refresh **proactively**
  before the call.
- `:143` — if the refresh token is locally expired, the session expires without a server call.
- `:201` — the stored refresh token's `exp` is what **corroborates** a non-authoritative 4xx.

So writing random garbage would trip local expiry checks and never exercise the refresh or
classifier paths at all. Each forged token must be a real three-part base64url JWT
(`header.payload.signature`) with an `exp` claim set deliberately. Copy the
`https://api.sahha.ai/claims/profileId` claim across from the existing token so
`authSnapshot.profileId` stays populated and data-log IDs keep a stable identity. The
surrounding JSON must stay decodable — decode the existing `TokenResponse`, replace one
field, re-encode. A JSON blob that will not decode exercises the D10 unreadable-keychain
path instead, which is a different test.

### 3.2 Stress Lab screen (Dart, new route)

| Control | Behaviour | Scenario |
| --- | --- | --- |
| Race: configure → gated call | Fire `configure()` and `getScores()` back to back **without awaiting** configure | D1 |
| Cold-launch race toggle | Persisted flag; when on, `main.dart` fires `getScores()` immediately after the startup `configure()` and surfaces the result | D1 |
| Deauth during upload | `postSensorData()` then `deauthenticate()` ~300 ms later | D3 |
| Deauth hammer | Five concurrent `deauthenticate()` calls | D4 |
| Repeat configure ×2 | Two sequential `configure()` calls | observation only |
| `enableMotionTrigger` toggle | Persisted flag feeding the startup `configure()` call | E4 |
| Chaos buttons + inspector | One button per method above, results rendered into an on-screen activity log | — |

Follow the existing screens' patterns (`SensorPermissionView` / `SensorDiagnosticsView`):
`shared_preferences` persistence, newest-first capped activity log, `showResponseSheet` for
errors. Add the route to `main.dart` and a Home tile alongside Sensor Diagnostics.

**Repeat configure ×2 is observation, not a gate.** Sequential `configure()` calls build a
fresh container without disposing the previous one, so the old container's HealthKit
observers stay registered and its upload/monitor tasks keep running. That is a known open
item (the settings-equality-gated debounce follow-up), not a beta.3 regression. Record what
the console shows; do not fail the run on it.

### 3.3 Copy fix

`SensorPermissionView` still says calling with an empty list "exercises the SDK's default-set
behaviour". Post-remediation `enableSensors([])` is a guarded error that leaves the stored set
untouched (E3). Update the caption.

## 4. Scenarios

### S — Smoke (baseline before any sabotage)

**S1 — End-to-end pipeline comes up clean.** Fresh build, online, authenticate with a sandbox
profile. Generator seeds the realistic 7-day profile. Enable `[steps, sleep, heart_rate]`,
grant the sheet. Foreground once, then `postSensorData()`.
*Expect:* status `enabled`, arming and upload narration, data logs arriving within minutes.
**Do not proceed to sabotage until S1 passes** — every later scenario assumes this baseline.

### A — Store poisoning and healing

The 1.3.9 incident class: persisted sensor state that no longer decodes. The store now reads
leniently — heals what it can, reports what it cannot, and never destroys what is not its own.

**A1 — Legacy 1.3.7 names heal in place.** From S1: `poisonStoreLegacy`, inspect, force-quit,
relaunch, inspect again, check Diagnostics, then drip one new hour of steps.
*Expect:* store rewritten canonically (`biotin_intake`, `caffeine_intake`, `fat_intake`,
`sleep`, `steps`); the new sample still uploads; exactly one healed-values anomaly on the
dashboard listing the renamed values. The old behaviour this kills: every read failing
forever — one backfill, then permanent silence.

**A2 — Mixed unknown.** `poisonStoreMixed` → force-quit → relaunch → inspect.
*Expect:* heals to `["steps","sleep"]`, unknown dropped, one healed-values anomaly naming the
dropped value, collection continues.

**A3 — All-unknown (downgrade simulation).** `poisonStoreAllUnknown` → force-quit → relaunch →
inspect → `getSensorStatus`.
*Expect:* reads as empty (status `pending`) but **stored bytes untouched** — the inspector
proves the future-SDK state survived. One all-unknown anomaly. Re-enabling afterwards
overwrites it legitimately.

**A4 — Foreign value.** `poisonStoreForeign` → force-quit → relaunch → inspect.
*Expect:* reads empty, foreign value **left in place**, anomaly reports the value's *type name
only*, never the value.

**A5 — Undecodable bytes.** `poisonStoreGarbage` → force-quit → relaunch → `getSensorStatus`.
*Expect:* status `pending` (not a crash, not silence), anomaly reporting the byte count. Note
the contract: the lenient store never *throws* on read — the "could not be read" error path is
reserved for a store disposed mid-call, which external sabotage cannot reach.

**A6 — Anchors under pre-rename keys.** From S1 with several days of history:
`relocateAnchorsToLegacyKeys` (inspector: modern keys zero, legacy populated) → force-quit →
relaunch → drip one new hour → foreground.
*Expect:* **incremental resume** — only new samples upload. A duplicate flood of week-old
samples means the alias read failed and collection restarted from scratch: that is the
pre-fix upgrade symptom and a hard fail.

### B — Offline launch and bring-up retry

**B1 — Offline cold launch recovers when the network returns.** From S1: airplane mode on,
force-quit, launch. Console shows `[SahhaActor] Authenticated bring-up deferred (…)`;
`isAuthenticated` stays true. Wait ~1 minute foregrounded, then airplane mode off.
*Expect:* the network-transition trigger **bypasses the backoff** — bring-up completes within
seconds, no relaunch, no user action. `[Network Monitor]` fires, then full arming narration,
then uploads resume.

**B2 — Backoff cadence and event bypasses.** Repeat B1 but stay offline ~10 minutes, console
attached; timestamp the deferral lines. While waiting, background/foreground once and
lock/unlock once.
*Expect:* timer retries ~30s doubling toward a 15-minute cap with ±25% jitter, 8 attempts per
budget; each foreground and unlock adds an immediate bypass attempt, never closer than the 5s
floor. After connectivity returns — even post-budget — the next foreground or network event
still recovers: exhaustion parks, it does not kill.

### C — Health check and background delivery

**C1 — Steady state is quiet and single-flight.** From S1, foreground several times.
*Expect:* `[SensorHealthCheck]` narration each cycle with nothing missing and no repairs, and
no repair errors on the dashboard. A healthy device staying silent is the pass.

**C2 — Externally dropped delivery is re-armed at next launch.** From S1:
`disableAllHKBackgroundDelivery` → background the app (do not quit) → drip new steps →
confirm **no** delivery wake (the sabotage took) → force-quit → relaunch → let bring-up finish
→ background → drip again.
*Expect:* delivery works again after relaunch. Bring-up re-runs arming (observer +
`enableBackgroundDelivery`) for every enabled sensor, which is the recovery path for iOS
dropping registrations across updates and restores. Note the honest scope: the health check
detects against the SDK's own bookkeeping, so *external* HK-state loss is healed by the
bring-up re-arm, not by the health check.

**C3 — Background delivery end to end.** App backgrounded, phone unlocked, generator writes
fresh heart-rate samples.
*Expect:* observer fires in the background and samples upload without the app being opened.

### D — Auth lifecycle

**D1 — Auth-gated calls wait for configure.** Stress Lab race button (warm), then the
cold-launch toggle with force-quit relaunches, repeated a few times since races are
probabilistic.
*Expect:* every run returns scores or a *real* API error — **never**
`Unauthorized. Please call `Sahha.authenticate(...)` first.` while authenticated. That exact
message on a cold launch is the regression.

**D2 — Deauthentication is total.** From S1 with anchors and history: `inspectStorage`,
deauthenticate, inspect again, re-authenticate, `getSensorStatus`.
*Expect:* post-deauth the `sensors` key is gone, anchor keys gone (both modern and legacy
prefixes), keychain token and demographic gone, **`deviceId` retained** — a field version of
the purge-completeness test. Post-re-auth: status `pending`; the sensor set is account-scoped
and must be re-enabled by design.

**D3 — Deauthenticate mid-upload.** Generator seeds a bulk day so there is real payload in
flight, then Stress Lab "Deauth during upload"; re-authenticate and re-enable afterwards.
*Expect:* deauth succeeds; **no** "Max retry attempts exceeded" from the cancelled flight; no
ghost re-upload of the torn-down batch after re-auth.

**D4 — Deauth is idempotent under abuse.** Five concurrent calls; repeat offline; repeat while
already deauthenticated.
*Expect:* every call succeeds, every time.

**D5a — Locally expired profile token refreshes proactively.** `expireProfileToken` →
force-quit → relaunch → `getScores`.
*Expect:* `AuthManager:73` sees the expired token and refreshes **before** the call; the call
succeeds; `isAuthenticated` stays true; nothing terminal on the dashboard.

**D5b — Server-rejected profile token heals reactively.** `invalidateProfileToken` →
force-quit → relaunch → `getScores`.
*Expect:* the token passes the local check, the server returns 401, a single-flight refresh
runs, and the call succeeds. Session stays alive.

**D6a — Locally expired refresh token expires the session cleanly.** `expireRefreshToken` →
force-quit → relaunch → `getScores` → check `isAuthenticated` → re-authenticate.
*Expect:* `AuthManager:143` short-circuits, the session expires without a server round trip,
the app returns to the auth screen, and normal re-auth works.

**D6b — Server-authoritative rejection.** `invalidateBothTokens` → force-quit → relaunch →
`getScores`.
*Expect:* refresh fails with an authoritative 401/403 and the session expires cleanly. The
guard under test: expiry must come from the corroborated classifier — a session dying on a
bare HTTP 400 is the regression this exists to prevent.

### E — enableSensors and getSensorStatus contracts

**E1 — Declarative replace.** Select All → ENABLE → check Diagnostics; then select only
`[steps]` → ENABLE → check again.
*Expect:* the second call **narrows** the enabled set to steps alone, visible in Diagnostics
and in the dashboard diagnostic report (which lists the expanded set). That visibility is the
support story for accidental narrowing.

**E2 — Non-HealthKit-only set.** From an HK-backed set, select only `[device_lock]` → ENABLE,
then `getSensorStatus([device_lock])`.
*Expect:* succeeds — no "Health data types not specified", **no HealthKit sheet**. Because the
previous set was HK-backed, the zero-HK replacement guard applies: the write stands, HK
teardown is skipped, and the replacement is reported to the dashboard.

**E3 — Empty set is a guarded error.** Select None → ENABLE, then check Diagnostics.
*Expect:* error `Sensor set cannot be empty.` and the persisted set **untouched** — the guard
fires before any write or teardown, so collection continues.

**E4 — The permission sheet has exactly one door.** *Run first, on a fresh install, before
anything calls `enableSensors`.* Configure and authenticate; foreground/background several
times; force-quit and relaunch; run `getSensorStatus`. Only then press ENABLE SENSORS.
Separately, flip the `enableMotionTrigger` toggle and relaunch.
*Expect:* no HealthKit sheet at all during the first phase (status `pending`) — launch,
retry, health check and probe never prompt. ENABLE SENSORS shows the sheet: the single door.
The motion toggle produces a separate Motion & Fitness prompt, the one documented exception,
opt-in and outside the HealthKit funnel.

### F — Volume and wedge regression

**F1 — Large historical backfill.** Generator seeds 90 days multi-metric **before**
`enableSensors`; enable the matching set and keep the app foregrounded.
*Expect:* backfill completes; anything hitting the 30s anchored-query timeout posts an error
and **moves on**; later sensors still arm (the 60s arming timeout guards the callback); the
full 90-day range appears in data logs.

**F2 — Dense-day stress.** Generator seeds one absurd day (10k+ samples: second-level heart
rate, minute-level steps). Trigger collection and note any timeout posts. **The regression
probe:** hours later or the next day, drip a small fresh batch and check background delivery.
*Expect:* the later drip still collects and uploads. The pre-fix failure mode was the wedge
*outliving* the load — task slots never released, observer completions never called, iOS
quietly suspending delivery, permanent silence after one bad day. Timeout errors are
acceptable; silence afterwards is the fail.

### G — Soak

**G1 — 48-hour ambient run.** After all groups pass, leave the app installed and
authenticated through 48h of normal phone use, with a small realistic generator drip daily.
*Expect:* data logs arrive daily without opening the app; no error-log flood (origin-keyed
dedup should hold repeats to one per origin per process); no battery complaint from iOS.

## 5. Generator seeding matrix

| Seed | Shape | Used by |
| --- | --- | --- |
| `realistic-week` | 7 days: sleep sessions, hourly steps, daytime heart rate | S1, A1–A6 |
| `daily-drip` | Small "today" batch (last hour of steps or HR), written on demand | A1, A6, C2, C3, G1 |
| `bulk-day` | One heavy day, enough that an upload takes visible time | D3 |
| `history-90` | 90 days multi-metric (sleep, steps, HR, HRV, active energy), written before enable | F1 |
| `dense-day` | 10k+ samples in 24h: second-level HR + minute-level steps | F2 |

The generator's LLM mode covers `history-90`; the manual config path is better for
`dense-day`, where exact volume matters. Clean up with the store cleaner between volume runs
so F scenarios stay reproducible.

## 6. Expected dashboard inventory

A core theme of the remediation is that formerly-swallowed failures now surface. During this
plan these error logs are **expected and correct**:

- Healed-values anomaly (A1, A2 — renamed and/or dropped names listed)
- All-unknown-values anomaly (A3)
- Foreign-value anomaly, type name only (A4)
- Undecodable-data anomaly, byte count (A5)
- Zero-HealthKit-backed replacement notice (E2)
- Anchored-query timeout posts under deliberate load (F1, F2)

These must **not** appear at any point:

- `Unauthorized. Please call `Sahha.authenticate(...)` first.` from a launch-time race (D1)
- "Max retry attempts exceeded" from a deauth-cancelled upload (D3)
- "Observer re-registration failed for N sensor(s): …" (C1 — would mean repair itself broke)
- Session expiry during D5a/D5b, or any expiry traceable to a bare HTTP 400
- Errors with a `null` location, or customer-identifying content of any kind

Anything on the dashboard outside this inventory during the run is a finding.
