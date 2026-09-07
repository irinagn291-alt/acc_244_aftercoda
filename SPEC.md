# Aftercoda — Build Specification

> Portfolio app 50, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Stamp the epicenter; bind a station only inside its coda.

| Field | Value |
| --- | --- |
| Product name | Aftercoda |
| Bundle identifier | `pro.aftercoda.ring` |
| Domain | https://aftercoda.pro |
| Contact URL | https://aftercoda.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `afc_` |
| User-Agent | `Aftercoda/1.0 (iOS; +https://aftercoda.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Aftercoda -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

The pulse opens a window.

### 2.1 User flow

1. Open today's anatomical clock: the 24h ring and body stay on screen.
2. Stamp a body region at an hour (scrub the ring or use now).
3. That region's coda sector lights; meals outside it cannot be bound.
4. Bind a meal already in the sector, or type one; comma-split parts become separate stations.
5. When a region×meal pairing has two matches it appears on the report sheet; score is matched over total pulses and a pairing with fewer than two matches is dropped.
6. Adjust per-region lookbacks and export the local report from Settings.

### 2.2 Essential behaviour

- Polar 24h clock that never leaves (Timeline is home).
- Body-region stamp; each region owns its lookback (head 6h, gut 3h, skin 12h).
- Bind meal to pulse only inside the coda sector.
- Meals split on comma or newline into stations.
- Correlation score matched/total; drop a pairing if matched is under 2.
- Report sheet and local export. No kcal, no slots, no Open Food Facts, no medical claims.

---

## 3. Uniqueness assignment for Aftercoda

| Axis | Assigned value |
| --- | --- |
| Architecture | **Windowed stream join (meal stream ⋈ pulse stream; lookback is the window)** |
| UI approach | **SwiftUI hosting a custom UIControl polar clock (UIGestureRecognizer-driven)** |
| Naming convention | **Seismology lexicon** |
| File organization | **By join side (meal pipeline, pulse pipeline, window join)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Smoked-drum seismograph (soot paper, silver stylus, teak drum)** |
| Typography | **Cochin** |
| Navigation pattern | **Dial-locked chrome (the 24h ring never leaves; bind and report arrive as sheets)** |
| AI art style | **Smoked-drum seismogram (needle trace on soot paper)** |
| Functional twist | **Region-owned coda window (lookback lives on the body region)** |
| Persistence | **JSON per day** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — food_symptom

**Core** — The pulse opens a window.

**Audience** — People hunting a timed trigger, not a calorie count — they already suspect food and need to see which meal sat inside the ache's own lookback.

**User flow**

1. Open today's anatomical clock: the 24h ring and body stay on screen.
2. Stamp a body region at an hour (scrub the ring or use now).
3. That region's coda sector lights; meals outside it cannot be bound.
4. Bind a meal already in the sector, or type one; comma-split parts become separate stations.
5. When a region×meal pairing has two matches it appears on the report sheet; score is matched over total pulses and a pairing with fewer than two matches is dropped.
6. Adjust per-region lookbacks and export the local report from Settings.

**Essential features**

- Polar 24h clock that never leaves (Timeline is home).
- Body-region stamp; each region owns its lookback (head 6h, gut 3h, skin 12h).
- Bind meal to pulse only inside the coda sector.
- Meals split on comma or newline into stations.
- Correlation score matched/total; drop a pairing if matched is under 2.
- Report sheet and local export. No kcal, no slots, no Open Food Facts, no medical claims.

**Twist** — Region-owned coda window. Each body region carries its own lookback. Stamping a region at hour T opens only that region's sector on the ring; meals outside the sector cannot be bound. A pairing is reported only after two matches. Home verb: stamp the epicenter, then bind a station inside the coda — not log-a-meal then log-a-symptom then open a chart.

**Why this is not a repeat** — Not a food_tracker: no OFF, no grams, no four slots, no Today macros. Not KcalCanvas: no 5-point mood on a calorie log. Not journal_chrome: home is one clock surface whose commit is stamp-then-bind, not Dashboard/Editor/Charts with swapped nouns. Not Sallyoak or any instrument_desk: no place-notation, no peal proof. The new verb is stamp a region so a coda sector opens, then bind only stations inside that sector; correlation is a counted pairing, not a black-box trigger.

### 3.0a Craft from the shipped portfolio

These rules come from apps that already shipped. Follow them. Do not copy their type names or layouts.

**Ship these. They are what made the real apps feel finished.**

- Home **is** the mechanic (canvas, rings, tower, wheel, matrix, dial, board, console). A tab plus a list of records is a clone.
- One persisted verb on home. Unit-test that verb. A decorative Game / Aura / Circuit / Nest / Sweep tab is filler — do not ship one.
- Every primary list has an empty state: generated art, one headline, one line, one CTA. Blank `List` fails.
- Simulator seed only, once, behind a versioned key. Never seed on a device.
- Contact URL on Settings (or Goals). App Review looks for it.
- Offline: if the product needs a catalog, a local shelf must catch empty/fail search. A spinner forever fails.
- Denied camera (when used) explains the state and routes to Settings. Silent no-op fails.
- Numbers go through `NumberFormatter`. Day edges use `Calendar.current.startOfDay`.
- One haptic on a successful commit, none on navigation.
- VoiceOver labels on every icon-only control. Colour is never the only signal.

**Review screenshots (21AUG App02–09)**

The running app, not `ImageRenderer`. One launch argument, three keys:

- `-ReviewScreen today` — home after onboarding (often a no-op)
- `-ReviewScreen log` — log / statement / planner
- `-ReviewScreen goals` — goals / targets / profile

Read `ProcessInfo.processInfo.arguments` **once**, **after** onboarding is done.
If onboarding is still showing, the hook never fires.

Companion (Simulator only):

- Seed one demo day behind a versioned key (`{prefix}.demo.v1`).
- Mark onboarding complete in the same seed so the hook is reachable.
- `#if targetEnvironment(simulator)`. Never seed on a device.
- Seed fills the primary surface (four slot posts from the local shelf).

Driver (outside the app): build → install on iPhone and iPad → launch with the
argument → wait until the UI settles → `xcrun simctl io <udid> screenshot`.
Name files `{App}-{today|log|goals}.png`. Pick any available simulator UDID.

**Family `food_symptom`**
- Home: Day board or 24h dial. Meals and pulses on one surface.
- Invariant (unit-test this): Lookback 0…6h. Split meal on comma/newline. score = matched/totalSymptoms; drop if matched<2. Not calories.
- Empty: The board is empty. Log a meal or a symptom.
- Fake that fails: A calorie tracker, or a black-box 'AI trigger'.
- Never: No GutGarden mini-game. No medical claims.

**Desk `bind_progress` — Binding stages**
- Home: Exploded binding cross-section.
- Invariant (unit-test this): progress mixes stages + sewn sections. Exploded binding is the home.
- Fake that fails: Reading journal.

### 3.1 Architecture contract

The app is a windowed stream join: a meal stream of stations and a pulse stream of region-stamped events. Each pulse opens a coda window whose width is the lookback stored on that pulse's body region, clamped to 0...6 hours. A station binds to a pulse only when its timestamp sits inside that window; meals outside the sector cannot join. The join emits a pairing count per region×station; score is matched over total pulses, and a pairing with matched under 2 is dropped. Meal pipeline, pulse pipeline, and window join stay separate types; views never compute the join.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI hosts one custom UIControl polar clock through a UIViewRepresentable. That control owns UIPanGestureRecognizer and UITapGestureRecognizer for ring scrub and now-stamp; it is the only UIKit surface and it never leaves the hub. Sheets, Settings, empty states, and the body figure are SwiftUI. Sector fills and traces are Path or Shape, not images.

### 3.3 Naming contract

Convention: Seismology lexicon.

Examples to follow: `CodaWindow`, `EpicenterStamp`, `StationRecord`, `PulseTrace`

### 3.4 Dependency contract

Zero external dependencies. project.yml has no packages key. Persistence is FileManager JSON. The polar clock is a local UIControl. No VisionKit, no Open Food Facts, no networking client.

### 3.5 Navigation contract

Dial-locked chrome: Timeline is the root and the 24h ring never leaves. Bind and Report arrive as sheets over the hub. Settings is a sheet from a control on that same hub. No tab bar. One haptic on a successful stamp or bind, none on presenting a sheet. ReviewScreen today stays on Timeline; log presents Report; goals presents Settings. Read ProcessInfo arguments once after onboarding.

### 3.6 Screen composition contract

Radial hub screens

Physical screens: Timeline, Report, Settings.

Timeline is the only full screen: the polar 24h ring and the anatomical body stay on canvas. BodyMap is that figure on Timeline, not a tab. Bind is a sheet over Timeline. Report is a sheet. Settings is a sheet for per-region lookbacks, local export, and the contact URL. Empty Timeline uses EmptyHome art, one headline, one line, one CTA to stamp. No Today, Scan, Search, or Goals.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By join side (meal pipeline, pulse pipeline, window join)**

```
Aftercoda/
  MealPipeline/
PulsePipeline/
WindowJoin/
Dial/
Store/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Timeline
A first-class screen for **Timeline**. Must render empty, populated and error states.

### 5.3 BodyMap
A first-class screen for **BodyMap**. Must render empty, populated and error states.

### 5.4 Report
A first-class screen for **Report**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **MealEntry** — named per this app's convention.
- **SymptomEntry** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Smoked-drum seismograph (soot paper, silver stylus, teak drum)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#14110E` | Screen background |
| `surface` | `#2A241C` | Cards, rows, sheets |
| `ink` | `#EDE6D6` | Primary text and icons |
| `accent` | `#C9B896` | Primary action, key figure, progress fill |
| `muted` | `#8C8274` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Cochin**

Cochin for all copy through one accessor. Cochin-Bold for titles, Cochin for body, at most six steps, none larger than 34pt. Scores and hours use NumberFormatter. Dynamic Type must keep ring labels readable.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **JSON per day**

One JSON file per calendar day under Application Support. The day key is the Unix timestamp in milliseconds of Calendar.current.startOfDay. Each file holds that day's stations and pulses. Writes go through one store protocol; views never touch FileManager. Debounce saves; resetAllData deletes the folder. Demo seed writes one day behind afc.demo.v1 on Simulator only.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Aftercoda/1.0 (iOS; +https://aftercoda.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.healthcare-fitness`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.healthcare-fitness
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Region-owned coda window (lookback lives on the body region)

Each body region owns its coda lookback. Stamping a region at hour T lights only that region's sector on the ring; the sector width is the region's lookback clamped to 0...6 hours. A station can be bound only if it already sits inside that sector, or if the user types one that the split places there. Head defaults to 6h, gut to 3h, skin to 6h; Settings can retune any region inside the same clamp. A region×station pairing appears on the report only after two matches; this is a counted join, not a medical claim and not an AI trigger.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Smoked-drum seismogram (needle trace on soot paper)**

Base prompt, reused and extended for every asset:

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `afc_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `afc_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `afc_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `afc_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `afc_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `afc_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `afc_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `afc_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `afc_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `afc_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `afc_TwistHero` | 1024x1024 | allowed | Hero art for the 'Region-owned coda window (lookback lives on the body region)' feature screen. |
| 11 | `afc_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `afc_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`afc_AppIcon`** — 1024x1024

```
teak drum end-cap with a silver needle arc on soot paper, filling the canvas, no text, no rounded corners
```

**`afc_Splash`** — 1290x2796

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, a vertical hero composition with a calm, uncluttered centre band
```

**`afc_Onboarding1`** — 1024x1536

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, a person or object that is this product in one glance
```

**`afc_Onboarding2`** — 1024x1536

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, the primary action of this product, mid-gesture
```

**`afc_Onboarding3`** — 1024x1536

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, a later moment when the product has accumulated meaning
```

**`afc_EmptyHome`** — 1024x1024

```
unused smoked drum, blank soot paper, silver stylus at rest, calm and inviting, never sad
```

**`afc_EmptyList`** — 1024x1024

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, an empty list, shelf or page
```

**`afc_CardBackdrop`** — 1200x800

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life, an abstract backdrop suitable for sitting behind a card
```

**`afc_ControlFace`** — 512x512

```
circular teak drum face with a 24-hour silver ring and one soot-paper coda sector
```

**`afc_TwistHero`** — 1024x1024

```
one body region lighting a coda sector on a smoked-drum ring, silver stylus, no text
```

**`afc_SuccessMark`** — 512x512

```
a short silver stylus puncture on soot paper, confirmation mark, no text
```

**`afc_HeaderDecor`** — 1200x600

```
wide teak grain band with a faint silver seismogram needle line, low contrast
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `afc.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `AftercodaTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Aftercoda -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Windowed stream join (meal stream ⋈ pulse stream; lookback is the window)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a custom UIControl polar clock (UIGestureRecognizer-driven)**.
- [ ] Navigation matches **Dial-locked chrome (the 24h ring never leaves; bind and report arrive as sheets)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Cochin** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Aftercoda
xcodegen generate
xcodebuild -scheme Aftercoda -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Aftercoda -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
