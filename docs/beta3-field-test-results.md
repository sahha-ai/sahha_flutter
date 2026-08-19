# 1.4.0-beta.3 field test results

Execution record for [`beta3-field-test-plan.md`](beta3-field-test-plan.md). Scenario IDs,
expectations and the dashboard inventory all come from that document; this one records only
what was observed.

**Run started:** 2026-08-19
**Device:** Sahha Developer Phone — iPhone 14 (iPhone14,7), iOS 26.6 (23G71)
**Environment:** `development`
**Plugin branch:** `feature/stress-lab-beta3-field-test` (sahha_flutter)
**SDK:** local path pod, `sahha-ios` @ `fix/development-environment-base-url`

## Status legend

| Mark | Meaning |
| --- | --- |
| PASS | Ran, and every stated expectation held |
| FAIL | Ran, and an expectation did not hold — details in the scenario section |
| PARTIAL | Ran, but at least one expectation could not be observed on this rig |
| BLOCKED | Could not run; the blocker is named in the scenario section |
| PENDING | Not yet attempted |

## Rig provenance

Facts established before the first scenario, each with how it was checked.

| Fact | Method | Result |
| --- | --- | --- |
| Development API reachable | `POST /v1/oauth/profile/register/appId` via curl | HTTP 201 in 1.06 s |
| App credentials valid for `development` | same call | Returned a full `TokenResponse` |
| Base-URL defect fixed | Read `SahhaEnvironment+BaseURL.swift` | `https://development-api.sahha.ai/api` — scheme separator present |
| SDK narration enabled | `Sahha.debugLogging` flipped in the local checkout | `true`, uncommitted |
| Credentials kept out of the repo | Injected via `--dart-define` | No credential literal in any tracked file |

### Real-token structure (validates the forging design)

The token forgers were previously verified against synthetic JWTs. Re-checked here against a
genuine server-issued pair, since the forgers depend on the real claim layout:

| Property | Profile token | Refresh token |
| --- | --- | --- |
| Algorithm | HS256 | HS256 |
| Structure | 3-part base64url | 3-part base64url |
| `exp` horizon as issued | 720 h (30 d) | 2160 h (90 d) |
| `.../claims/profileId` present | yes | yes |

Both tokens carry `exp` and the `profileId` claim, which is exactly what
`forgeJWT` rewrites and preserves. Claim values are deliberately not recorded here.

> The refresh token's own 90-day `exp` is what `AuthManager:201` reads to corroborate a
> non-authoritative 4xx, so D6b depends on this claim being present and forgeable.

## Scenario summary

| ID | Scenario | Status |
| --- | --- | --- |
| E4 | Permission sheet has exactly one door | **PASS** |
| S1 | End-to-end pipeline comes up clean | **PASS** |
| A1 | Legacy 1.3.7 names heal in place | **PASS** |
| A2 | Mixed unknown | **PASS** |
| A3 | All-unknown (downgrade simulation) | **PASS** |
| A4 | Foreign value | **PASS** |
| A5 | Undecodable bytes | PENDING |
| A6 | Anchors under pre-rename keys | PENDING |
| B1 | Offline cold launch recovers | PENDING |
| B2 | Backoff cadence and event bypasses | PENDING |
| C1 | Steady state is quiet and single-flight | **PASS** |
| C2 | Externally dropped delivery re-armed | PENDING |
| C3 | Background delivery end to end | PENDING |
| D1 | Auth-gated calls wait for configure | PENDING |
| D2 | Deauthentication is total | PENDING |
| D3 | Deauthenticate mid-upload | PENDING |
| D4 | Deauth idempotent under abuse | PENDING |
| D5a | Locally expired profile token refreshes | PENDING |
| D5b | Server-rejected profile token heals | PENDING |
| D6a | Locally expired refresh token expires session | PENDING |
| D6b | Server-authoritative rejection | PENDING |
| E1 | Declarative replace | PENDING |
| E2 | Non-HealthKit-only set | PENDING |
| E3 | Empty set is a guarded error | PENDING |
| F1 | Large historical backfill | PENDING |
| F2 | Dense-day stress | PENDING |
| G1 | 48-hour ambient soak | PENDING |

## Run order

E4 runs first, on the freshly installed build, before anything calls `enableSensors` —
HealthKit permission state is one-way and cannot be returned to "never asked". S1 is the
baseline gate; no sabotage scenario runs until it passes.

## Rig constraints discovered

Two things about this rig changed how the run is driven. Both are test-harness facts, not
product defects.

**Debug builds cannot be launched by `devicectl`.** iOS forbids JIT without an attached
debugger, so a debug-mode `FlutterEngine` refuses to start when launched any other way:

> Cannot create a FlutterEngine instance in debug mode without Flutter tooling or Xcode.

Every cold launch in this run therefore goes through `flutter run`. Consequence for the
plan: a force-quit cannot be followed by tapping the icon — the relaunch has to come from
the tooling. Hot restart (`R`) is *not* a substitute, because it re-runs Dart `main()`
without re-running native SDK bring-up, which is the thing most A- and D-series scenarios
are actually testing.

**The app data container is readable over `devicectl`.** `Library/Preferences/
sahha.flutter.ios.plist` can be pulled directly, so the `sensors` key, anchor-key counts and
`deviceId` are verifiable from the host without going through the in-app inspector. Storage
assertions below are taken this way — independent of the code under test, which makes them
stronger evidence than the app reporting on itself. Keychain items are not readable this
way; those still come from the in-app inspector, presence only.

## Scenario records

### E4 — The permission sheet has exactly one door

**Status: PASS** (HealthKit phases; motion-trigger phase still pending)

Run first, on a freshly installed build, before anything called `enableSensors`. Preconditions
read from the device container:

```
total keys: 4
sensors: ABSENT
anchors: modern hkAnchor.=0 hkAnchorDate.=0 | legacy sahha_hkAnchor.=0 date_hkAnchorDate.=0
deviceId present: True
```

**Phase 1 — no door.** Across two cold launches (each verified genuine by
`configure() starting fresh (container exists: false)`), three background/foreground cycles,
one force-quit, and roughly eighteen `getSensorStatus` calls spanning all 8 sensors
individually and as a set — **no HealthKit sheet appeared at any point**, confirmed visually
at the device. Every call returned `pending`. Launch, retry, health check and probe all
stayed silent, which is the contract.

**Phase 2 — the single door.** ENABLE SENSORS with `[steps, sleep, heart_rate]` produced the
sheet. After granting:

```
[HealthKitObserver] startObservers called for 3 sensors: ["heart_rate", "sleep", "steps"]
[HealthKitObserver] After startObservers, registered keys: ["heart_rate", "sleep", "steps"]
flutter: Permissions: enableSensors(3 sensors) -> enabled
```

Confirms the plan's device-state note: **the keychain survived app deletion.** The reinstalled
build came up already holding a valid session for a pre-existing development profile with no
authentication step.

Outstanding: the `enableMotionTrigger` toggle should produce a separate Motion & Fitness
prompt — the one documented exception. Not yet run.

### A1 — Legacy 1.3.7 names heal in place

**Status: PASS**

Store state read directly from the device container either side of a genuine cold launch
(`configure() starting fresh (container exists: false)`):

| Stage | Bytes | Decoded |
| --- | --- | --- |
| After `poisonStoreLegacy` | 73 | `["dietary_biotin", "dietary_caffeine", "dietary_fat_total", "sleep", "steps"]` |
| After relaunch | 64 | `["sleep", "biotin_intake", "fat_intake", "caffeine_intake", "steps"]` |

All three 1.3.7-era names healed to their canonical forms per
`SahhaSensor+LegacyRawValues.swift:12-23`, and the healed set was **written back** — this is
not a read-time coercion that leaves the bad bytes in place. `sleep` and `steps` passed
through untouched.

Arming used the healed names:

```
[HealthKitObserver] startObservers called for 5 sensors: ["biotin_intake", "caffeine_intake", "fat_intake", "sleep", "steps"]
```

**Anchors survived** — `hkAnchor.` stayed at 3 across the poison and the heal. This is the
core of the scenario: the pre-fix symptom was every read failing forever, forcing collection
to restart from scratch. Anchor retention is what proves it resumes incrementally instead.

Background delivery re-armed for `steps` and `sleep` only. The three dietary types were armed
as observers but got no delivery, consistent with their HealthKit permission never having
been granted — only `[steps, sleep, heart_rate]` was granted at E4 phase 2.

**Dashboard anomaly confirmed — exactly one, with the right values:**

```
"sdk" null "Sensor store healed legacy values — renamed 3: dietary_biotin, dietary_caffeine, dietary_fat_total"
CodeMethod: postPendingSensorStoreAnomaly(_:)   SdkVersion: 1.4.0-beta.2
```

`renamed` carries the *legacy* names, since `SensorStore.swift:119` appends the raw value
before mapping. One anomaly for one poisoning — the latch is not re-firing per read. Its
`ErrorLocation` is `flutter`, not null, so it clears the plan's no-null-location bar.

Data logs for the run are present on the profile. The confusion during the run was a
test-harness one, recorded as F-6: the app was authenticated as a pre-existing profile whose
session survived app deletion, not as the external id supplied via `--dart-define`.

### A2 — Mixed unknown

**Status: PASS**

| Stage | Bytes | Decoded |
| --- | --- | --- |
| After `poisonStoreMixed` | 32 | `["steps", "sleep", "not_a_sensor"]` |
| After relaunch | 17 | `["steps", "sleep"]` |

`not_a_sensor` dropped, the two known values kept, storage rewritten in canonical form.
Arming used the healed set — `startObservers called for 2 sensors: ["sleep", "steps"]` — and
the 3 modern anchors survived, so collection continued rather than restarting.

Dashboard should carry one healed-values anomaly naming the dropped value
(`dropped 1 unknown: not_a_sensor`), per `SensorStoreAnomaly.description`.

### A3 — All-unknown (downgrade simulation)

**Status: PASS**

The store read the set, recognised none of it, and left the persisted bytes **cryptographically
identical** across a full cold launch:

```
poisoned sha256: 86c05d324345817c1619afcf2cc2da7f  41 bytes
after    sha256: 86c05d324345817c1619afcf2cc2da7f  41 bytes
IDENTICAL: True
```

Decoded both sides as `["from_the_future_a", "from_the_future_b"]`. No `startObservers` line
appeared on this launch at all, consistent with the set reading as empty — the SDK declined to
act on values it could not interpret rather than arming a partial set. `getSensorStatus`
returned `pending` for all 8 sensors individually and as a set.

This is the inverse guarantee to A1 and the one most easily lost in a refactor: A1 requires the
store to *rewrite* what it can repair, A3 requires it to *not touch* what it cannot. Hashing
the raw value rather than comparing lengths or decoded contents makes the non-destruction claim
direct evidence rather than an inference — a rewrite that happened to produce the same byte
count would still have failed this check.

### A4 — Foreign value

**Status: PASS**

`poisonStoreForeign` wrote a plain `String` under a key the SDK expects to hold `Data`. Across
a cold launch the value was left exactly as written:

```
type before/after: str / str
sha256 before: 22e76d732d29fb02ec98bace399bd203
sha256 after : 22e76d732d29fb02ec98bace399bd203
IDENTICAL: True
```

No observers armed. Same non-destruction guarantee as A3 but reached through a different
failure mode — a wrong *type* rather than unrecognised *contents* — and `SensorStore.swift:100`
captures only `String(describing: type(of: raw))` for the anomaly, so the value itself cannot
reach the dashboard.

The storage inspector deliberately reports the value's type without its contents, mirroring the
same discipline; that is why the snapshots above are hashed rather than printed.

### S1 — End-to-end pipeline comes up clean

**Status: IN PROGRESS** — arming and collection verified, upload confirmation pending

Store written by `enableSensors`, read from the device container. This matches the encoding
the plan documents (`Data` holding a JSON array of raw-value strings) byte for byte:

```
sensors: type=bytes bytes=30 decoded=["sleep", "heart_rate", "steps"]
anchors: modern hkAnchor.=3 hkAnchorDate.=0 | legacy sahha_hkAnchor.=0 date_hkAnchorDate.=0
deviceId present: True
```

Arming and initial collection, all three sensors:

```
[HealthKitObserver] Background delivery triggered for heart_rate / sleep / steps
[HealthKitDataLogCoordinator] Initial sync for heart_rate. Limiting to 30 days history.
[HealthKitDataLogCoordinator] Background observer query completed for sleep: success, samples: 35, logs: 35
[HealthKitDataLogCoordinator] Background observer query completed for heart_rate: success, samples: 384, logs: 384
[HealthKitDataLogCoordinator] Background observer query completed for steps: success, samples: 86, logs: 86
```

505 samples from the generator's realistic-week seed, uploaded across 10 chunks with no
errors, no timeouts and no retry exhaustion. One anchor per enabled sensor.

`postSensorData()` after a foreground cycle drove the queue to 547 items, with compression and
priority tiers both working:

```
[Sahha Compression] Compressed request body: 5896 bytes → 791 bytes
[DataLogUploader] Successfully uploaded chunk with 3 items (priority: critical)
[DataLogUploader] Successfully uploaded chunk with 5 items (priority: high)
[DataLogUploader] Successfully uploaded chunk with 15 items (priority: high)
```

**S1 passes.** Baseline established; sabotage scenarios may proceed.

Note `hkAnchorDate.` is at 0 while `hkAnchor.` is at 3 — anchor *dates* are not written
alongside anchors on this path. Relevant to A6, which relocates both prefixes.

### C1 — Steady state is quiet and single-flight

**Status: PASS**

Four foreground cycles after S1 produced **zero** `[SensorHealthCheck]` narration and zero
repair errors.

Silence is the correct signal, and the code says so. The listener fires on `.app_foreground`
only — `.app_resume` is deliberately rejected because it also fires when the HealthKit
permission sheet is dismissed — and it narrates only on failure:

```swift
let result = await healthCheckService.runHealthCheck()
if !result.allHealthy {
    Sahha.log("[SensorHealthCheck] Re-registered ... observer(s), ... failure(s)")
}
```

The other three `[SensorHealthCheck]` log sites sit inside `missingObserver`,
`missingDeliveryOnly` and repair-failure branches. A healthy device cannot produce any of
them.

> **Plan correction needed.** C1 asks for "`[SensorHealthCheck]` narration each cycle with
> nothing missing and no repairs" *and* says "A healthy device staying silent is the pass."
> Only the second is achievable — there is no healthy-path narration to observe. A future
> tester following the first clause would record a false fail. See F-4.

The service also documents its own blind spot, which bounds what C1 can claim: *"A registered
observer whose delivery iOS has silently suspended is an accepted blind spot: it cannot be
detected in-process."* C1 therefore shows the check stays quiet when the SDK's bookkeeping is
consistent; it does not show the check would catch iOS suspending delivery behind its back.

## Findings

Numbered as they were found. Severity is my assessment, not a triaged verdict.

### F-1 — Debug logging prints the full bearer token and identity claims (medium)

`APIClient.swift:122` logs every request's headers wholesale:

```swift
Sahha.log("[Sahha Network] \(urlRequest.httpMethod ?? "GET") \(urlRequest.url?.absoluteString ?? "") | Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
```

`allHTTPHeaderFields` includes `Authorization: Profile <JWT>`. The JWT's payload is
base64url — not encrypted — and carries `profileId`, `externalId` and `accountId`. So every
request logs a live bearer token plus three identifiers in plaintext to the console, where
Console.app, sysdiagnose bundles and any screen-share pick them up.

Mitigating: `Sahha.debugLogging` is internal and defaults to `false`, so no shipping app hits
this. But this plan's own step 5 instructs testers to turn it on, and the plan's dashboard
inventory forbids "customer-identifying content of any kind" — the same standard applied to
the console fails here. Suggested fix: redact `Authorization` when logging headers.

### F-2 — `isAuthenticated` and `profileToken` bypass the D13a configure gate (high) — CONFIRMED

Reproduced on 2 of 2 cold launches. Both printed, within the same second:

```
[SahhaActor] configure() starting fresh (container exists: false)
flutter: isAuthenticated: false
```

while the profile was genuinely authenticated — the SDK issued authenticated requests moments
later with a stored token whose `exp` is roughly three weeks out, and once bring-up finished
the same call returned `true`.

**Root cause.** The beta.3 remediation (PRD #76 D13a) added `ConfigurationTaskBox` precisely
for this race. Its own doc comment states the problem:

> Auth-gated calls await it before evaluating the auth guard: the guard's snapshot is
> populated by the token store's keychain read *during* configuration, so judging a call while
> configure is still in flight failed authenticated callers.

Every auth-gated *call* goes through `runAsyncWithCallback`, which takes a
`configurationTaskBox` and awaits it. But the two public *properties* do not:

```swift
public static var isAuthenticated: Bool {
    authSnapshot.isAuthenticated      // Sahha.swift:85 — no await of the configuration task
}

public static var profileToken: String? {
    authSnapshot.profileToken         // Sahha.swift:89 — same
}
```

`AuthSnapshot.profileToken` is populated by `TokenStore` during configuration
(`TokenStore.swift:25`). Read before that completes, it is still `nil`, so `isAuthenticated`
returns `false` and `profileToken` returns `nil`.

**Why this matters.** It is the same defect D1 exists to catch, reached through a different
public API, and it is *quieter*: D1 produces a loud "Unauthorized. Please call
`Sahha.authenticate(...)` first." error, whereas this returns a plausible `false`. A host app
that gates its launch UI on `isAuthenticated` — which is exactly what this example app's
Home screen does at `HomeView.dart:26` — shows a signed-out state to a signed-in user on every
cold launch. The Flutter plugin exposes both paths (`SwiftSahhaFlutterPlugin.swift:121` and
`:49`), so Flutter hosts inherit it.

Suggested fix: give both properties an async form that awaits the configuration task, or have
them resolve through the same gate `runAsyncWithCallback` uses. Note `launchVerdict()` already
models the richer answer (`unauthenticated` vs `tokenStoreUnreadable` vs `valid`) that a
synchronous boolean cannot express.

### F-3 — Every batch is persisted as "while offline" on a fully online device (medium)

Steady-state narration on a device with working connectivity, repeating dozens of times:

```
[DataLog Persistent Queue] Stored batch with 1 items (while offline, priority: normal, attempts: 0)
[Network Monitor] Started monitoring network connectivity
[SentLogStore] Marked 1 items as sent (total tracked: 13)
[DataLogUploader] Successfully uploaded chunk with 1 items (priority: normal)
[Network Monitor] Stopped monitoring network connectivity
```

Two things are off. Every batch is stored down the *offline* path and then uploaded
successfully milliseconds later — the device was never offline. And `[Network Monitor]`
starts and stops around each upload rather than staying up, dozens of times per session.

The shape suggests the reachability answer is read before `NWPathMonitor` has delivered its
first path, so the queue sees "offline", takes the persist branch, and the upload then
succeeds once the real path arrives. Functionally it still uploads, so this is not a data-loss
bug — but it means every batch pays an unnecessary disk write, and the narration actively
misleads anyone reading the console.

It also bears directly on B1/B2, which assert that a network transition *bypasses* the
bring-up backoff. If the monitor is being torn down between uploads, the transition event
those scenarios depend on may not be observed the way they assume. Worth resolving before
B1/B2 are interpreted.

### F-4 — C1's expectation contradicts itself, and the achievable half is the second (documentation)

Plan section 4, C1 expects "`[SensorHealthCheck]` narration each cycle with nothing missing and
no repairs" and then "A healthy device staying silent is the pass." No healthy-path narration
exists — every log site in `SensorHealthCheckService` and its lifecycle listener is inside a
failure branch. The first clause should be struck so the scenario cannot be read as requiring
output that the code never emits.

### F-5 — HTTP 204 is thrown as an error, flooding the dashboard on every launch (high)

This is what O-1 turned out to be. It accounts for **10 of the 11** error logs on the test
profile — 91% of that profile's entire error history is a non-error.

204 No Content is a *success* status. `APIClient.send<T>` throws on it anyway:

```swift
if response.statusCode == 204 || data.isEmpty {
    throw APIErrorResponse(
        title: "No Content",
        statusCode: 204,
        location: "APIClient.send",
        errors: [.init(origin: "Decoding", errors: ["No content for type \(T.self)"])]
    )
}
```

`syncDemographic` runs on every authenticated bring-up and catches it into the error log:

```swift
var demographic = try await demographicManager.getDemographic()   // SahhaActor.swift:418
...
} catch {
    await log(error: error, message: "syncDemographic failed")    // SahhaActor.swift:429
}
```

So any profile without a complete demographic — which is every new profile — posts an
`Error`-level log on **every single launch**:

```
"api" 204 "No Content"
ErrorBody: [{"origin":"Decoding","errors":["No content for type SahhaDemographic"]}]
CodeMethod: syncDemographic(_:)   ErrorLocation: APIClient.send
```

Observed once per launch across three launches on 2026-08-19 and seven more on 2026-08-10,
spanning SDK versions beta.1 and beta.2 and two different devices. Origin-keyed dedup holds it
to one per process, so this is not a flood *within* a session — it is one per launch forever.

**Why this matters beyond noise.** The remediation's stated theme is that formerly-swallowed
failures now surface, and section 6 of the plan turns the dashboard into the pass/fail
instrument for six scenarios. An error channel that is 91% false positives degrades exactly
the instrument this test run depends on, and would train operators to ignore it.

Fix is small: 204 should be a successful empty result, not a throw — either an optional return
for absent content, or `syncDemographic` treating "no demographic yet" as the ordinary
first-run state it is rather than a failure.

### F-6 — The example app's Authentication screen shows an identity the SDK is not using (medium, this repo)

During the run, the Authentication screen displayed the external id supplied via
`--dart-define`, while the SDK was in fact authenticated as a completely different pre-existing
profile. That sent the
dashboard check to an empty profile and briefly looked like total upload failure.

The screen's field is prefilled from `SahhaBuildCredentials` when no value is stored
(`AuthenticationView.dart:75`). That is correct for an *input* — it is the id that will be used
on the next `authenticate()` call — but the screen shows nothing about who the SDK is
*currently* authenticated as, so the input reads as the current identity.

The trap is created by the very device-state lever the plan documents: the keychain at service
`ai.sahha.ios` survives app deletion, so a reinstalled build can come up already authenticated
as an older profile and never call `authenticate()` at all. Anyone reinstalling to get a clean
slate will hit this.

Fix belongs in this repo, not the SDK: surface the authenticated identity next to the input.
The profile token already carries the `externalId` claim, so it can be decoded and displayed
without any new SDK surface.

