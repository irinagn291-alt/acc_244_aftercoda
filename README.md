# Aftercoda

Stamp the epicenter. Bind a station only inside its coda.

Aftercoda is for people who already suspect food and need to see which meal sat inside an ache’s own lookback. Home is today’s anatomical clock: a 24h smoked-drum ring and a body figure that never leave. Stamp a region at an hour; that region’s coda sector lights; stations outside it cannot bind. Comma or newline splits a typed meal into stations. A region×station pairing appears on the report only after two matches. Score is matched over total pulses, not calories.

No account, no ads, no Game tab. The dial is the mechanic.

## Architecture

Windowed stream join. A meal stream of `StationRecord` values meets a pulse stream of `PulseTrace` stamps. Each pulse opens a `CodaWindow` whose width is the lookback stored on that pulse’s `BodyRegion`, clamped to 0…6 hours. `WindowJoin` is the only type that binds a station to a pulse; views never compute the join and never touch `FileManager`. Persistence is one JSON file per calendar day behind `TraceStore`. SwiftUI hosts a single `UIControl` polar clock (`RingControl`) for scrub and now-stamp.

This fits a timed trigger hunt: the legal move is stamp-then-bind inside a region-owned sector, not log-a-meal then log-a-symptom then open a chart. A tab plus a list of records would be a clone.

## Region-owned coda

This is why someone would pick the drum. Each body region carries its own lookback (head 6h, gut 3h, skin asks 12h and is clamped to 6h). Stamping a region at hour T lights only that sector. A station binds only when its timestamp already sits inside the sector, or when a typed line is split onto that hour. Settings can retune any region inside the same clamp. A pairing with fewer than two matches is dropped. This is a counted join, not a medical claim and not an AI trigger.

Invariant, unit-tested:

Lookback 0…6h. Split meal on comma/newline. `score = matched / totalSymptoms`; drop if `matched < 2`. Not calories.

Desk `bind_progress`: progress mixes completed stages with sewn sections. Exploded binding is the home measure.

## Design

Smoked-drum seismograph: soot paper, silver stylus, teak drum. Palette lives in `Assets.xcassets` and is reached only through `DrumInk`: background `#14110E`, surface `#2A241C`, ink `#EDE6D6`, accent `#C9B896`, muted `#8C8274`. Type is Cochin for every step of a six-step scale (title, heading, mark, body, callout, caption). Hard edges. Spacing unit 8 pt. Tap targets 44 pt. Navigation is dial-locked: Timeline stays; Bind, Report, Settings, and the coda twist arrive as sheets.

## Art

Style: smoked-drum seismogram (needle trace on soot paper).

Base prompt reused for every asset:

```
smoked-drum seismograph, soot-black paper, silver stylus needle trace, teak drum cylinder, warm low raking light, no text, no logos, museum-object still life
```

| Image set | Prompt |
| --- | --- |
| `afc_AppIcon` | teak drum end-cap with a silver needle arc on soot paper, filling the canvas, no text, no rounded corners |
| `afc_Splash` | Base prompt, a vertical hero composition with a calm, uncluttered centre band |
| `afc_Onboarding1` | Base prompt, a person or object that is this product in one glance |
| `afc_Onboarding2` | Base prompt, the primary action of this product, mid-gesture |
| `afc_Onboarding3` | Base prompt, a later moment when the product has accumulated meaning |
| `afc_EmptyHome` | unused smoked drum, blank soot paper, silver stylus at rest, calm and inviting, never sad |
| `afc_EmptyList` | Base prompt, an empty list, shelf or page |
| `afc_CardBackdrop` | Base prompt, an abstract backdrop suitable for sitting behind a card |
| `afc_ControlFace` | circular teak drum face with a 24-hour silver ring and one soot-paper coda sector |
| `afc_TwistHero` | one body region lighting a coda sector on a smoked-drum ring, silver stylus, no text |
| `afc_SuccessMark` | a short silver stylus puncture on soot paper, confirmation mark, no text |
| `afc_HeaderDecor` | wide teak grain band with a faint silver seismogram needle line, low contrast |

## How this is not a repeat

Family `food_symptom`, not a food tracker: no Open Food Facts, no grams, no four slots, no Today macros. Not a calorie tracker and not a black-box AI trigger. Home is one clock whose commit is stamp-then-bind. Distinct from KcalCanvas, journal_chrome dashboards, Sallyoak, and any instrument_desk. No GutGarden mini-game. No Game tab.

## Build

```bash
cd Aftercoda
xcodegen generate
xcodebuild -scheme Aftercoda -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `pro.aftercoda.ring`. Contact: https://aftercoda.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `afc.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
