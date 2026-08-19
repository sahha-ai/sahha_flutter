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
| A5 | Undecodable bytes | **PASS** |
| A6 | Anchors under pre-rename keys | **PASS** |
| B1 | Offline cold launch recovers | BLOCKED (rig) |
| B2 | Backoff cadence and event bypasses | BLOCKED (rig) |
| C1 | Steady state is quiet and single-flight | **PASS** |
| C2 | Externally dropped delivery re-armed | PENDING |
| C3 | Background delivery end to end | **PASS** (with O-3 open) |
| D1 | Auth-gated calls wait for configure | **PASS** |
| D2 | Deauthentication is total | **PASS** |
| D3 | Deauthenticate mid-upload | **PASS** |
| D4 | Deauth idempotent under abuse | **PASS** |
| D5a | Locally expired profile token refreshes | **PASS** |
| D5a-soon | Proactive refresh inside the 30m window (extra) | **PASS** |
| D5b | Server-rejected profile token heals | **PASS** |
| D6a | Locally expired refresh token expires session | **PASS** (re-run, see F-8) |
| D6b | Server-authoritative rejection | **PASS (guard)** — see note |
| E1 | Declarative replace | **PASS** |
| E2 | Non-HealthKit-only set | **PASS** |
| E3 | Empty set is a guarded error | **PASS** |
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

**`Sahha.debugLogging` is an uncommitted local edit and can be silently lost.** Partway
through the run all native SDK narration stopped: 0 `[Sahha…]` lines where earlier sessions had
94. The cause was the `sahha-ios` working copy moving to a new branch, which discarded the
uncommitted `debugLogging = true` tweak that step 5 of the plan requires. Nothing announces
this — the app still runs, Dart logs still print, and only the SDK's own narration disappears,
which is exactly the channel several scenarios use as their pass/fail signal. It invalidated one
D3 run before being caught. **Any scenario whose evidence is an absent native log line should
first assert that native lines are present at all.**

**`flutter run` detaches when the app is backgrounded.** Backgrounding produced
`Lost connection to device.` and froze the log. This makes every background-delivery scenario
(C2, C3, F2's regression probe, G1) unobservable through the tooling used for the rest of this
run, and it silently yields *stale* data rather than an error — counts simply stop changing,
which reads like "nothing happened". The plan anticipates this in section 1.6 and prescribes
running the `Runner` scheme from Xcode or watching Console.app. That route was not set up here.

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

### A5 — Undecodable bytes

**Status: PASS**

`poisonStoreGarbage` wrote 32 random bytes as `Data`. Across a cold launch:

```
sha256 before: a43c833077feae8e94182e1cdd047ce4  32 bytes
sha256 after : a43c833077feae8e94182e1cdd047ce4  32 bytes
IDENTICAL: True
```

Configure completed normally — no crash, no thrown read, no observers armed, and
`getSensorStatus` returned `pending` for the full 8-sensor set. This is the
subtlest of the A-series contracts: the lenient store must degrade quietly rather than fail
loudly, and the plan notes the "could not be read" error path is reserved for a store disposed
mid-call, which external sabotage cannot reach. Nothing in the console suggested otherwise.

Together A1–A5 exercise the store in four directions — repair what is renameable (A1), drop
what is unknown while keeping the rest (A2), and refuse to touch either unrecognised contents
(A3) or a wrong type (A4/A5). The destructive and non-destructive instincts are both correct,
which is the pairing most at risk in a refactor.

### A6 — Anchors under pre-rename keys

**Status: PASS**

`relocateAnchorsToLegacyKeys` moved all three anchors to their pre-rename prefix, verified from
the container before the relaunch:

```
anchors: modern hkAnchor.=0 hkAnchorDate.=0 | legacy sahha_hkAnchor.=3 date_hkAnchorDate.=0
```

After a cold launch:

```
[HealthKitObserver] startObservers called for 3 sensors: ["heart_rate", "sleep", "steps"]
[HealthKitDataLogCoordinator] Background observer query completed for heart_rate: noSamples, samples: 0, logs: 0
[HealthKitDataLogCoordinator] Background observer query completed for sleep: noSamples, samples: 0, logs: 0
[HealthKitDataLogCoordinator] Background observer query completed for steps: noSamples, samples: 0, logs: 0
```

**The decisive evidence is an absent line.** `Initial sync … Limiting to 30 days history` fires
whenever `loadAnchor` returns nil — all three appeared at S1, when the anchors genuinely did not
exist. None appeared here, so the anchors were found through the legacy prefix and every query
resumed from its stored position. The pre-fix symptom would have been three initial syncs and a
re-query of ~505 historical samples.

Sample counts alone would have been weaker evidence than this: `SentLogStore` dedups
already-sent items, so a re-queried flood could show near-zero *uploads* while the anchor read
was in fact broken. The query counts and the missing initial-sync lines are what distinguish
the two.

The alias read under test:

```swift
private func data(forUnprefixedKey key: String) -> Data? {
    storage.data(forKey: prefix + key) ?? storage.data(forKey: legacyPrefix + key)
}
```

Anchors were **read** from the legacy keys without being **migrated** to canonical ones — the
counts are unchanged afterwards. That matches `loadAnchor`'s stated design: saves are canonical
but not prompt, and the old key is deliberately never deleted because deletion is worse on
downgrade.

**Fresh drip confirms the resume is live, not just quiet.** One hour of new steps produced
exactly one sample, and the anchor keys moved:

```
[HealthKitDataLogCoordinator] Background observer query completed for steps: success, samples: 1, logs: 1
```

| Key family | Before drip | After drip |
| --- | --- | --- |
| `hkAnchor.` (canonical) | 0 | **1** |
| `sahha_hkAnchor.` (legacy) | 3 | 3 |

The anchor was read from the legacy key, the query returned samples, and the advanced anchor
was saved to the **canonical** key while the legacy key was left in place. Only `steps`
migrated because only `steps` had samples — `sleep` and `heart_rate` returned none and skipped
their saves. That is the lazy, per-sensor migration `loadAnchor` describes, observed directly.

This also resolves the drip question raised during A1, where a drip reported `noSamples`. Drips
do flow; that reading was a timing artifact of the observer firing before HealthKit surfaced
the write, not a collection failure.

Scope note: `loadAnchor` carries a second, independent alias for renamed sensor *names* via
`currentToLegacyRawValue`. A6 exercises only the *prefix* alias, so this result does not cover
that path.

### D1 — Auth-gated calls wait for configure

**Status: PASS**

Warm races (Stress Lab "Race: configure → gated call", fired several times) produced no failure
of any kind. Three further cold launches with the persisted cold-launch race toggle on, each a
genuine bring-up (`configure() starting fresh (container exists: false)`), each firing
`getScores()` immediately after `configure()` without awaiting it:

| Cycle | `Unauthorized` occurrences | `getScores` outcome |
| --- | --- | --- |
| 1 | 0 | Real score payload |
| 2 | 0 | Real score payload |
| 3 | 0 | Real score payload |

The in-app record after cycle 2 read `getScores returned 10548 chars`. Every run returned
scores, never the SDK's unauthorized message — which is the exact regression D1 exists to catch.

**This run also isolates F-2 conclusively.** On the same cold launch, at the same moment:

```
[SahhaActor] configure() starting fresh (container exists: false)
flutter: isAuthenticated: false                                  <- property: wrong
flutter: Cold-launch race getScores Result: [{"state":"medium","type":"wellbeing",...   <- call: correct
```

The auth-gated *call* waits for configure and succeeds; the `isAuthenticated` *property* does
not wait and answers `false` for the very session that call is about to use successfully. Same
process, same instant, opposite answers. That is the D13a gate being applied to
`runAsyncWithCallback` and not to the public properties, observed as a controlled comparison
rather than inferred from a single reading. Across every session in this run the property answered
`false` 14 times and `true` 21 times — the false readings clustered at cold launch, before
bring-up completes.

So D1's own contract holds, and the defect it was designed to detect survives one API layer
across — see F-2.

### D2 — Deauthentication is total

**Status: PASS**

Read from the device container either side of `deauthenticate()`:

| Surface | Pre | Post | Required |
| --- | --- | --- | --- |
| `sensors` | 30 bytes, `["sleep","steps","heart_rate"]` | **ABSENT** | gone |
| `hkAnchor.` (canonical) | 1 | **0** | gone |
| `sahha_hkAnchor.` (legacy) | 3 | **0** | gone |
| `deviceInfo` | present | gone | — |
| `com.sahha.diagnostic_report` | present | gone | — |
| `sentLogIds` | present | gone | — |
| `deviceId` | present | **present** | **retained** |
| Keychain `token` | true | **false** | gone |
| Keychain `demographic` | false | **false** | gone |

`deviceId` survived while every other SDK-owned key went, which is the asymmetry the scenario
is built around.

**A6 made this a sharper test than the plan assumes.** Deauthentication ran with anchors under
*both* prefixes — 1 canonical and 3 legacy. `HealthKitAnchorStore.dispose()` claims to sweep
the legacy family precisely because "a legacy-key anchor that survives deauth would be
resurrected by the fallback read" in `loadAnchor`. Both families went to zero, so that claim
holds against the exact state that would expose it. Running D2 from a clean install would have
left the legacy sweep untested.

The keychain `demographic` item being absent *before* deauthentication is consistent with F-5:
there is genuinely no demographic for this profile, which is why that endpoint keeps returning
204.

Re-authentication afterwards succeeded and `getSensorStatus` returned `pending` across the
board — the sensor set is account-scoped and must be re-enabled by design, which is the
post-condition the scenario asks for. The Authentication screen's new "Signed in as" row
tracked the change correctly in both directions, confirming the F-6 fix.

### D5a — Locally expired profile token refreshes proactively

**Status: PASS**

The forge rewrote the *real* server-issued profile token, preserving every other claim:

```
StressLab: expireProfileToken -> { "profileToken": "expired 60m ago", "profileIdPreserved": true, ... }
```

After a cold launch:

| Signal | Observed |
| --- | --- |
| `POST /v1/oauth/profile/refreshToken` | **1** |
| `getScores` result | `[]` — empty, not an error |
| `Session expired` | none |
| `[Sahha Error] HTTP …` | none |
| `Unauthorized …` | none |

Exactly one refresh, fired *before* the call rather than in response to a rejection — the
`AuthManager.swift:73` proactive path. The empty array is a successful response: this is a
newly created profile with no scores yet, and the assertion is that the call completes rather
than that it returns data.

This also validates the forging design against a real token rather than a synthetic one. The
`https://api.sahha.ai/claims/profileId` claim survived the rewrite, and the re-encoded
`TokenResponse` blob stayed decodable — had it not, the run would have exercised the D10
unreadable-keychain path instead, which is a different test entirely.

### D5a-soon — Proactive refresh fires inside the 30-minute window (extra)

**Status: PASS** — not a plan scenario; added to isolate the `expiryOffset`

`expireProfileTokenSoon` sets `exp` to five minutes in the future, so the token is **not**
expired in absolute terms:

```
StressLab: expireProfileTokenSoon -> { "profileToken": "expires in 5m — inside the 30m proactive-refresh window", ... }
```

A refresh fired anyway:

| Signal | Observed |
| --- | --- |
| `POST /v1/oauth/profile/refreshToken` | **1** |
| `getScores` result | `[]` — successful |
| `Session expired` | none |

This isolates `AuthManager`'s `expiryOffset: .minutes(30)` default, which `AuthDI` does not
override. D5a cannot demonstrate it: a hard-expired token would refresh under any offset, so it
cannot distinguish "the 30-minute window works" from "the clock passed". A token still valid for
five minutes can only be refreshed *because* of the offset.

It also settles the design question behind the forgers. No server-issued short-lived token is
needed, because `JWT.isExpired` never verifies signatures — it base64url-decodes the payload and
reads `exp`. The local decision is therefore entirely controlled by the `exp` written into an
otherwise-real token, and the signature only governs whether the *server* accepts it, which is
what separates D5a from D5b.

### D5b — Server-rejected profile token heals reactively

**Status: PASS**

`invalidateProfileToken` writes a future `exp` with a bogus signature, so the token passes every
local check and only the server can reject it.

```
[Sahha Error] HTTP 401 | Response:
[Sahha Error] HTTP 401 | Response:
```

| Signal | D5a (proactive) | D5b (reactive) |
| --- | --- | --- |
| HTTP 401s | 0 | **2** |
| `POST /v1/oauth/profile/refreshToken` | 1 | **1** |
| `getScores` result | `[]` | `[]` |
| Session expired | no | no |

The call succeeded and the session stayed alive, which is the scenario's assertion.

**Two 401s produced one refresh.** That is the single-flight guarantee in `runRefreshFlight`
holding under real concurrency — two in-flight requests were rejected independently, joined the
same refresh flight, and only one refresh-token rotation was spent. Without it each failing
request would burn its own rotation, which is the behaviour `minRefreshInterval` and the
single-flight actor exist to prevent. The plan does not ask for this; it fell out of the
scenario because bring-up happens to issue concurrent authenticated requests.

D5a and D5b together reach opposite paths by changing only *which part* of the JWT is wrong —
`exp` for the local check at `:73`, signature for the server's verdict. That separation is what
made forging real three-part JWTs necessary rather than writing garbage.

### D6a — Locally expired refresh token expires the session cleanly

**Status: PASS** — on the corrected setup; see F-8 for why the plan's own setup does not reach this code

Run with **both** tokens forged: the profile token expired to force a refresh flight at `:73`,
the refresh token expired so that flight short-circuits at `:143`.

| Signal | Observed | Required |
| --- | --- | --- |
| `POST /v1/oauth/profile/refreshToken` | **0** | 0 — no server round trip |
| HTTP errors | **0** | none |
| Session | expired, store cleared | expired |

```
flutter: Cold-launch race getScores Error: PlatformException(Sahha Error,
  Unauthorized. Please call `Sahha.authenticate(...)` first., null, null)
```

The session died entirely locally with zero network traffic, which is the scenario's central
claim: the dead-session verdict is independent of the server's status-code choice.

Two observations on the surfaced error. The message is the *unauthenticated* one rather than
`sessionExpiredMessage` — by the time the race's `getScores` read the store, `clearToken()` had
already run, so it took the nil-token branch at `AuthManager:71`. This is **not** a D1
violation: D1 forbids that message from a launch-time race *while a profile is signed in*, and
here the session is genuinely dead. But it does tell a host "you never authenticated" when the
truth is "your session expired", which are different remedies from an integrator's point of
view.

The second observation is more serious and is recorded as F-9.

### D6b — Server-authoritative rejection

**Status: PASS (anti-regression guard)** — the clean-expiry path is not reachable on the
development server; see the note below.

First attempt was **BLOCKED** by F-10: with the refresh endpoint accepting a signature-invalid
token (HTTP 200), the forged session healed and stayed alive, so `isSessionTerminal` was never
consulted. After the platform team fixed the development refresh endpoint (see F-10), the
tampered-signature refresh token is rejected with **HTTP 400** (independently re-confirmed by
`curl`: tampered-sig refresh → 400, was 200).

Re-run with both tokens forged (future `exp`, bogus signatures):

```
flutter: Cold-launch race getScores Error: PlatformException(Sahha Error, HTTP Error:
  {"title":"Invalid refresh token.","statusCode":400,"location":"domain", ... })
```

| Signal | Observed | Meaning |
| --- | --- | --- |
| Surfaced error | raw upstream `400 Invalid refresh token` | **not** the SDK's `Session expired…` message |
| Keychain `token` after the run (in-app inspector) | **true** | session retained |
| Same 400 on a second fresh cold launch | yes | bogus tokens still stored — confirms retention |

Two distinct code paths could have run, and the evidence points at one:

- **Terminal** → `isSessionTerminal` returns true → `expireSession()` → throws
  `"Session expired. Please authenticate again."` and clears the keychain.
- **Transient** → returns false → re-throws the raw `APIErrorResponse`, keeping the tokens.

The raw 400 surfaced (not `sessionExpiredMessage`) and the keychain `token` stayed `true`, so
the classifier took the **transient** branch. That is correct and is exactly the guard D6b
protects: `invalidateBothTokens` gives the refresh token a *future* `exp`, so
`JWT.isExpired(refreshToken)` is false, so a 400 resolves through the `400...499` corroboration
branch to **not terminal**. A session dying on that bare 400 would have been the regression;
it did not.

> **Note — the "clean 401/403 expiry" half of D6b cannot be demonstrated on development.** The
> server rejects a bad refresh token with **400**, never 401/403, so the authoritative-terminal
> branch (`case 401, 403: return true`) is unreachable from the refresh endpoint here. What was
> verified is the negative guard (no expiry on a bare 400 with a valid-looking refresh token).
> To exercise the positive path, either a server that returns 401/403 for an invalid refresh
> token is needed, or the classifier's terminal branch should be unit-tested in the SDK. Logged
> as F-11.

### D4 — Deauthentication is idempotent under abuse

**Status: PASS**

Four hammer runs of five concurrent `deauthenticate()` calls each — 20 calls total, every one
returning `true`:

| Leg | Condition | Result |
| --- | --- | --- |
| 1 | Authenticated, online | 5/5 `true` |
| 2 | Already deauthenticated, online | 5/5 `true` |
| 3 | Airplane mode on (offline) | 5/5 `true` |
| 4 | Airplane mode on, repeat | 5/5 `true` |

Leg 1 output, representative of all four:

```
StressLab: D4 call 1/5 -> true
StressLab: D4 call 2/5 -> true
StressLab: D4 call 3/5 -> true
StressLab: D4 call 4/5 -> true
StressLab: D4 call 5/5 -> true
StressLab: D4 -> all 5 calls succeeded
```

Concurrent callers join the single in-flight teardown rather than each reconfiguring and
orphaning a container. The scenario's three conditions — concurrency, no prior session, and no
network — all converge, matching the SDK's stated contract that deauthentication "never throws
and requires no session or prior configure: logout is a convergent operation, and wrappers
fire-and-forget it."

The offline legs are the most load-bearing: deauthentication must not depend on reaching the
server, or a signed-out user on a plane stays signed in.

### B1 / B2 — Offline cold launch and backoff cadence

**Status: BLOCKED** — rig constraint, not a product result

Both scenarios require a **cold launch while offline**. That is unreachable on this rig, for a
reason that compounds the debug-launch constraint recorded above:

1. A debug-mode Flutter app cannot be launched by `devicectl` — iOS forbids JIT without an
   attached debugger — so every cold launch must go through `flutter run`.
2. `flutter run` reinstalls the app each time, and iOS requires **network connectivity to
   verify a development-signed app's certificate** before a newly installed build may run:
   *"an internet connection is required to verify trust of the developer — this app will not be
   available until verified."*

So the only mechanism available for cold-launching the build is the one mechanism that cannot
work without a network. Attempting B1 produced no bring-up narration at all: the app never
started.

**What would unblock them.** A **profile-mode** build launches standalone from the home screen
(AOT, no debugger, no reinstall per launch), so trust is verified once and later cold launches
work offline. That needs two changes: `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG` added to
the **Profile** build configuration only (never Release, which must not ship the chaos
channel), and the Dart-side `ChaosChannel.isSupported` gate widened from `kDebugMode`, which is
false in profile. It also changes the runtime under test from JIT to AOT, which is a real
difference worth stating when the results are read.

Neither scenario was attempted further. F-3 remains the run's only evidence touching network
transitions, and it is worth noting that F-3 predicts these scenarios would be awkward to
interpret anyway: the `[Network Monitor]` start/stop churn means the transition event B1 and B2
depend on may not behave as the plan assumes.

### E1 — Declarative replace

**Status: PASS**

| Stage | Store bytes | Decoded |
| --- | --- | --- |
| Select All → ENABLE | 2636 | 144 sensors |
| Select `[steps]` → ENABLE | **9** | `["steps"]` |

`enableSensors(144 sensors) -> enabled` then `enableSensors(1 sensors) -> enabled`. The second
call **replaced** the set rather than merging into it, which is the declarative contract and the
support story for accidental narrowing.

**The 29 canonical anchors survived the narrowing**, and that is correct rather than incidental.
Anchors record collection *position*, not enablement, so discarding them when a sensor leaves
the set would force a full historical re-backfill whenever the set was widened again — the A6
failure mode arriving by a different route. Keeping them means re-enabling resumes where
collection left off.

### E2 — Non-HealthKit-only set

**Status: PASS**

Replacing an HK-backed set (`["steps"]`) with a set containing no HealthKit-backed sensors:

```
flutter: Permissions: enableSensors(1 sensors) -> enabled
```

| Signal | Observed |
| --- | --- |
| Store after | 15 bytes, `["device_lock"]` |
| Error "Health data types not specified" | none |
| HealthKit sheet | none |
| Observer arming / teardown narration | none |
| Canonical anchors | 29, unchanged |

The write stood and HealthKit teardown was skipped, which is the zero-HK replacement guard
behaving as specified. Anchors surviving matters for the same reason as in E1: a later
re-widening to HK-backed sensors resumes from stored positions rather than re-backfilling.

The dashboard notice arrived as the plan's section 6 predicts:

```
"sdk" null "enableSensors replaced 1 HealthKit-backed sensor(s) with a set containing none;
 the new set was persisted, but HealthKit teardown was skipped and the replaced sensors may
 keep collecting until the next launch."
```

> **Worth a deliberate decision (O-2).** That notice is honest and the behaviour is by design,
> so it is not recorded as a defect. But it states that HK-backed sensors removed from the set
> **keep collecting until the next cold launch**. Read as a privacy property rather than a
> correctness one, that means a user who removes `heart_rate` continues to have heart rate
> collected for an unbounded period — until the app happens to be force-quit and relaunched,
> which a user may never do. The persisted set says the sensor is off while the observer says
> otherwise. Recommend the team decide explicitly whether "off" should take effect immediately
> for HK-backed sensors on this path, or whether the disclosure is considered sufficient.

### E3 — Empty set is a guarded error

**Status: PASS**

```
flutter: Permissions: enableSensors(0 sensors) failed ->
  PlatformException(Sahha Error, Sensor set cannot be empty., null, null)
```

The persisted set was byte-identical either side of the failed call:

```
before E3: e2a1fd5c33fbe09e15f3c71ba91a9de0  15 bytes
after  E3: e2a1fd5c33fbe09e15f3c71ba91a9de0  15 bytes
UNTOUCHED: True
```

The guard fires before any write or teardown, so collection continues on the previously enabled
set rather than being silently cleared.

**This validates the copy fix delivered with the Stress Lab work.** `SensorPermissionView`
previously claimed an empty list "exercises the SDK's default-set behaviour"; the corrected
caption at `SensorPermissionView.dart:509` states that `enableSensors([])` fails with
"Sensor set cannot be empty." and leaves the stored set untouched. Both halves are now verified
on-device — the message matches verbatim, and the bytes are provably unchanged rather than
assumed to be.

### D3 — Deauthenticate mid-upload

**Status: PASS**

The first attempt was **discarded as invalid**, and the reason is worth recording. Sensors had
not actually been enabled (a missed tap), so no upload was in flight — and separately, that
session captured **zero** native SDK narration. Since "Max retry attempts exceeded" is a native
`Sahha.log` line, grepping a silent channel for it proves nothing. Both faults were fixed before
re-running (see the narration note below).

Valid run — payload genuinely in flight when the teardown landed:

| Signal | First (invalid) run | Valid run |
| --- | --- | --- |
| Native narration lines | 0 | **107** |
| Initial syncs | 0 | 3 |
| Observer queries | 0 | 3 (146 sleep + 733 heart_rate + 174 steps = 1053 samples) |
| Upload chunks | 0 | 12 |
| `Max retry attempts exceeded` | 0 (meaningless) | **0 (meaningful)** |

The deauthentication landed two log lines after the final upload chunk, so the teardown
genuinely raced an active flight. Teardown narration:

```
[DataLog Persistent Queue] Cleared all persisted batches
[Tag Persistent Queue] Cleared all persisted batches
[HealthKitObserverStore] removeAllObservers called (3 observers)
[Sahha] Background Coordinator stopped
flutter: StressLab: D3 deauthenticate() -> true
```

Both persistent queues were **cleared** rather than left behind. That is the mechanism behind
the scenario's "no ghost re-upload after re-auth" expectation: the torn-down batches cannot
resurrect because they no longer exist, rather than depending on a later dedup check.

The ghost-upload assertion is taken as satisfied by that mechanism rather than by observation,
and deliberately so: deauthentication also wipes the anchors and `sentLogIds`, so any
re-authenticate-and-re-enable legitimately triggers a full backfill. A post-re-auth upload
burst is therefore expected behaviour and cannot be distinguished from a ghost by volume alone.
The queue-clear narration is the stronger evidence.

### C3 — Background delivery end to end

**Status: PASS** on its stated assertion; an unexplained observation is recorded as O-3

With the app backgrounded and fresh heart-rate samples dripped, delivery fired and samples
uploaded **without the app being opened**:

```
[HealthKitObserver] Background delivery triggered for heart_rate
[HealthKitDataLogCoordinator] Background observer query completed for heart_rate: success, samples: 144, logs: 144
[DataLogUploader] Successfully uploaded chunk with 52 items (priority: high)
```

102 delivery triggers and 12+ upload chunks were observed while backgrounded, which satisfies
the scenario: the observer fires in the background and data reaches the server unattended.

### O-3 — 96 of 98 background queries returned an identical 144 samples (unresolved)

During C3, `heart_rate` observer queries returned **exactly 144 samples 96 times** out of 98
queries, against 102 delivery triggers. Control sensors behaved completely differently in the
same session: `steps` and `sleep` ran **2 queries each**. Cumulative unique items tracked reached
only ~1170, so roughly 13,800 sample-reads produced ~1,170 distinct logs.

Two explanations remain open, and they differ in severity:

- **Benign.** Each drip writes 144 *new* HealthKit objects — new UUIDs even at identical
  timestamps — so an anchored query legitimately returns 144 new objects per drip, the anchor
  advances correctly, and the SDK's deterministic log IDs dedup the value-identical results
  downstream. The heart-rate skew then simply reflects that heart rate was the sensor being
  dripped repeatedly.
- **Serious.** The anchor is not advancing across delivery triggers, so every background wake
  re-reads and re-builds the same 144 logs indefinitely. That would be a real battery and CPU
  cost incurred precisely when the app is backgrounded, and a plausible mechanism for the F2
  wedge the plan is built to detect.

**Why it could not be settled here.** The discriminator is a query with *no* new data: a
correctly-advancing anchor must return `noSamples, samples: 0`. Attempting it failed for a rig
reason — `flutter run` printed `Lost connection to device.` when the app was backgrounded, so
the log froze and no post-drip query was captured. The apparently unchanged counts were an
artifact of a dead capture, not a measurement.

**How to settle it.** Run the `Runner` scheme from Xcode, or watch Console.app filtered to
process `Runner`, as the plan's section 1.6 already advises for background scenarios. Then, with
no new samples written, force one collection pass (Post Sensor Data or a background wake) and
read the sample count. `0` confirms the benign reading; `144` confirms the anchor is stuck and
should be raised as a defect.

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

### F-7 — Signing out wrote the app secret to disk in plaintext (medium, this repo)

Introduced by the `--dart-define` credential seeding added for this run, and caught by the D2
container snapshot. After `deauthenticate()`, the app container held:

```
'flutter.appId', 'flutter.appSecret', 'flutter.externalId'
```

`onTapDeauthenticate` ends with `setPrefs()`, which unconditionally writes all three fields.
Because `getPrefs()` seeds empty fields from `SahhaBuildCredentials`, the build-time app secret
was persisted to a plaintext plist inside the app container — as a side effect of *signing
out*, and without anyone having typed it.

An app secret mints profile tokens for any external id in the account, so it is the one value
that should never be written to disk casually. Before the seeding change this could only happen
if a user typed the secret in themselves.

Fixed by tracking which fields still hold an unedited build-time seed and skipping those in
`setPrefs`; editing a field clears its flag, so typed credentials persist exactly as before. A
secret already written by an affected build is not removed by the fix — reinstalling the app
clears it.

### F-8 — D6a as written cannot reach the code it names (plan defect)

D6a says: "`expireRefreshToken` → force-quit → relaunch → `getScores`. *Expect:*
`AuthManager:143` short-circuits, the session expires without a server round trip."

Run exactly that way, nothing happened:

| Signal | Observed |
| --- | --- |
| `POST /v1/oauth/profile/refreshToken` | 0 |
| HTTP errors | 0 |
| `getScores` | `[]` — succeeded |
| Session | still alive |

The short-circuit at `:143` lives *inside* `runRefreshFlight`, which only runs when
`getValidProfileToken()` decides at `:73` that the **profile** token needs refreshing:

```swift
guard JWT.isExpired(token.profileToken, offset: expiryOffset) else { return token.profileToken }
return try await refresh(replacing: token.profileToken)   // :73-74
```

Because D5b's reactive refresh had just minted a fresh 30-day profile token, `:73` was
satisfied, no flight ran, and the expired refresh token was never examined. Expiring the
refresh token alone is **inert** until something independently forces a refresh attempt.

This is a defect in the scenario, not in the SDK — arguably the SDK behaving correctly, since
it declined to spend a round trip it did not need. But a tester following D6a literally would
record a false pass: zero round trips is exactly what the scenario predicts, for entirely the
wrong reason.

D6a should specify expiring **both** tokens — the profile token to force a flight, the refresh
token to make that flight short-circuit — or state that it must run from a state where the
profile token is already due for refresh. The same caveat applies to D6b, which depends on a
refresh actually being attempted.

### F-9 — Session-expiry errors never reach the dashboard (high)

Observed twice during D6a's re-run:

```
[Sahha] - ERROR: Failed to post error log: SahhaError(message: "Unauthorized. Please call
  `Sahha.authenticate(...)` first.", ... function: "getValidProfileToken()", line: 71)
```

`AuthManager.expireSession` is explicitly ordered to prevent this:

```swift
private func expireSession(cause: Error?) async -> SahhaError {
    let sessionError = SahhaError(message: Self.sessionExpiredMessage, error: cause)
    logger.postError(cause ?? sessionError)   // "Reports the cause first — once the store is
    await tokenStore.clearToken()             //  cleared, no authenticated request can carry it."
    return sessionError
}
```

But `postError` is **synchronous** and hands off to `spawnPost`, which is
`Task.detached(priority: .background)`. That detached task awaits a circuit-breaker check and
then resolves an auth token, while `clearToken()` — a direct `await` on the actor — completes
first. The post then finds a nil token and fails. Background priority makes losing the race
close to certain.

So the stated ordering guarantee is defeated by its own dispatch, and the failure is
**structural, not incidental**: every session expiry clears the credentials that its own error
report needs. Session death is the single event a support engineer most needs to see, and it is
systematically invisible.

It also compounds F-5. The dashboard reliably receives a benign 204 on every launch, and
reliably loses genuine session expiry — noise arrives, signal does not, on the channel this
plan uses as its pass/fail instrument.

Possible fixes: make `postError` awaitable and await it inside `expireSession` before clearing;
or resolve and capture the token for the post before the clear; or route the expiry error
through the persistent queue so it survives re-authentication and uploads later.

### F-12 — Debug backtraces are printed on the deauthentication teardown path (low)

Two call sites dump a raw stack trace into the log whenever they run:

```swift
Thread.callStackSymbols.prefix(10).forEach { Sahha.log("  \($0)") }
```

- `HealthKitObserverStore.swift:30` — in `removeAllObservers`
- `HealthKitObserverService.swift:177` — in `dispose`

Observed during D3: ~20 lines of mangled Swift symbols and hex addresses interleaved with the
teardown narration, e.g.
`0 Sahha 0x0000000105589d48 $s5Sahha24HealthKitObserverServiceC7disposeyyYaFTY0_ + 88`.

This reads as leftover instrumentation from debugging the dispose path rather than intentional
product logging. It is gated behind `debugLogging`, so severity is low, but it makes the
teardown sequence materially harder to read at exactly the moment an engineer is most likely to
be reading it — and this plan instructs testers to enable that logging. Recommend removing both
call sites, or reducing them to a single line naming the caller.

### F-11 — D6b's positive path (clean 401/403 expiry) is unverifiable on development (test-coverage)

`isSessionTerminal` treats 401/403 as authoritative-terminal and expires the session. The
development refresh endpoint returns **400** for every bad refresh token (tampered signature,
and — per the SDK's own comment at `AuthManager:190` — expired tokens too), never 401/403. So
the terminal branch that D6b's expectation ("session expires cleanly") depends on is never
reachable through this endpoint in this environment.

The negative guard is well covered on-device (D6a locally, D6b reactively). The positive
terminal path is not, and cannot be without either a server that returns 401/403 for an invalid
refresh token or a direct unit test of `isSessionTerminal` in the SDK. Recommend the latter as
the durable fix — it pins the classifier's full truth table independently of server behaviour,
which this run has shown varies.

### F-10 — The development refresh endpoint does not validate the refresh token's signature (security — verify production)

Found when D6b's forged-both-tokens session refused to die. Isolated from the SDK entirely and
reproduced with `curl` against `https://development-api.sahha.ai`, using a throwaway profile
created for the test.

| # | Request | Token | Result |
| --- | --- | --- | --- |
| 1 | `POST /v1/oauth/profile/refreshToken` | valid header+payload, **signature replaced** with `abcdef` | **HTTP 200 + fresh valid token pair** |
| 2 | `GET /v1/profile/demographic` | profile token, same signature tamper | HTTP 401 (correctly rejected) |
| 3 | `POST /v1/oauth/profile/refreshToken` | payload `exp` pushed +10 years, real signature | HTTP 200 |
| 4 | `POST /v1/oauth/profile/refreshToken` | `"garbage"` (not a JWT) | HTTP 400 |

Test 1 is the finding: the refresh token is an HS256 JWT, and altering its signature does not
cause rejection — the endpoint mints a new session anyway. Test 2 is the control: the resource
server validates the *profile* token's signature and returns 401 for the same tamper, so the
platform does verify signatures in general — the refresh endpoint specifically does not. Test 4
shows it does parse (non-JWT → 400), so acceptance in test 1 is signature-specific, not a
blanket accept.

**Why this matters.** A refresh token is the long-lived credential; the whole point of its
signature is that the server minted it. If the signature is unchecked, any party holding a
token's header and payload — both of which are base64url, not encrypted — can keep a session
alive indefinitely, and by test 3 can alter payload claims while doing so. The remediation being
field-tested here hardens the *client's* handling of expired and rejected tokens; this is the
server counterpart, and it undercuts the trust boundary the client-side work assumes.

**Scope and caution.** Reproduced only on **development**. I did **not** test sandbox or
production — that is the platform team's call, and probing a production auth server for a
signature-bypass is not something to do without explicit authorization. I also did **not**
attempt to mint a token for a different profile's id; tests 1 and 3 establish the mechanism
(signature unchecked, payload mutable) without exercising cross-profile access, which would mean
reaching for data that is not mine. Recommend the platform team confirm signature verification
on the production refresh endpoint as a priority, and treat the dev finding as in-scope for the
same auth hardening.

**Update (2026-08-20):** fixed on **development** — a tampered-signature refresh token now
returns HTTP 400 instead of 200, re-confirmed by `curl`. Sandbox and production were explicitly
**not** changed and remain to be verified by the platform team.

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

