<table align="center">
  <tr>
    <td align="center"><img src="docs/images/icon.png" width="200" alt="Hyht Light app icon — a black Celtic-knot motif on white"><br><sub>Light</sub></td>
    <td align="center"><img src="docs/images/icon-dark.png" width="200" alt="Hyht Dark app icon — a white Celtic-knot motif on black"><br><sub>Dark</sub></td>
  </tr>
</table>

# Hyht — an iOS countdown widget for enjoying the wait for one important day

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Platform: iOS 17.0+](https://img.shields.io/badge/Platform-iOS%2017.0%2B-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5-orange.svg)

**日本語のドキュメントは [README.md](README.md) にあります。**

---

Hyht (pronounced [hyçt]) is an iOS countdown widget for saving one important day and enjoying the time you spend looking forward to it. It keeps the time remaining visible on your Home Screen and Lock Screen, switching automatically from weeks to days, hours, clock time, and minutes as the moment approaches. A month out reads "4.29 weeks", ten days out reads "10.08 days", and the final stretch reads "87 min" — a granularity that fits how close the moment feels. It is a native WidgetKit port of a widget originally written in Scriptable (the JavaScript widget app); unlike the Scriptable original, there is no script to maintain, and the app runs fully locally with zero network access.

> **One event only.** Choose the one day you are most excited about, then keep your attention on the time leading up to it.

> **Not on the App Store.** You build it from source with Xcode. In the iOS Simulator it runs as-is with no Apple Developer account (no signing setup); only installing on a physical device requires selecting a Team in Xcode.

| Home Screen widgets (Bold) | Edit screen with live preview | Completion screen (Soft) |
|---|---|---|
| <img src="docs/images/homescreen.png" width="240" alt="Hyht widgets on an iOS Home Screen: the medium widget shows an emoji and the event name on the left with 10.08 days in large digits; the small widget shows large white digits on black"> | <img src="docs/images/editor-bold.png" width="240" alt="Hyht edit screen: a live widget preview on top, with a form for event name, emoji, and deadline, and the Minimal/Bold/Soft template picker below"> | <img src="docs/images/completion-soft.png" width="240" alt="Preview of the post-deadline completion display: a cream background with a party-popper emoji and a celebratory message"> |

## Make the Waiting Part of the Experience

iOS already gives you Calendar for dates and Reminders for notifications. But when you suddenly wonder "how long is left?", there is no obvious place to feel that time moving:

- **Checking the time should not take another action.** You should not have to open Calendar, count dates, or ask Siri. Look at your Home Screen and the remaining time is already there.
- **The countdown should change as the moment gets closer.** "23 days" three weeks out is hard to feel, and "0 days" three hours out says almost nothing. When the unit changes with the distance, you can feel a faraway plan gradually becoming now.
- **A personal widget should be easy to keep using.** Scriptable is a wonderful way to make exactly the display you want — that is how Hyht began. But not everyone wants to keep maintaining JavaScript or checking whether it still works after an iOS update.

Hyht is not for listing every upcoming date. It is for keeping one important day close: automatic five-stage unit switching, native WidgetKit placement on both Home Screen and Lock Screen, and a normal iOS app with no script to manage. The trade-off is that you cannot one-tap install it from the App Store — you build it from source.

## Quick Start

```bash
git clone https://github.com/hnsol/hyht.git
cd hyht
xcodegen generate   # generates Hyht.xcodeproj (not checked into git)
```

Open the generated `Hyht.xcodeproj` in Xcode and run on a simulator, or build from the CLI:

```bash
xcodebuild build -project Hyht.xcodeproj -scheme Hyht \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## The Display Changes as the Moment Gets Closer

Hyht uses a wider unit when the moment is far away and a more immediate one when it is close. Thresholds live in an external `mode-policy.json`, with a 30-second hysteresis (ε) at each boundary to damp flicker.

| Mode | Condition (time remaining) | Example | Format |
|---|---|---|---|
| Weeks | > 12 days + 30 s | `4.29 weeks` | 2 decimal places |
| Days | > 120 hours + 30 s | `10.08 days` | 2 decimal places |
| Hours | > 24 hours + 30 s | `36.5 hours` | 1 decimal place |
| Clock | ≥ 2 hours | `2:45` | H:mm |
| Minutes | < 2 hours | `87 min` | integer (floor) |
| Done | ≤ 0 | completion screen | message + emoji |

Decimal rounding is fully compatible with JavaScript's `Number.prototype.toFixed` (e.g. `(9.995).toFixed(2)` is `"9.99"`). So that no digit ever differs from the Scriptable original, the ECMAScript algorithm is reimplemented in pure integer arithmetic and verified against a golden fixture generated with Node.js.

## Features for Enjoying the Countdown

- **Three widget sizes** — Home Screen small and medium, plus the Lock Screen circular widget (accessoryCircular).
- **Focus on one event** — save only the one event you are most excited about.
- **Three design templates** — Minimal (white background, monospaced digits), Bold (black background, large white digits, red accent), and Soft (cream background, rounded font).
- **Live preview** — the edit screen renders a preview using the exact same rendering code as the real widget, switchable by size (small / medium / circular) and state (active / completed).
- **Autosave, no Save button** — edits are saved with a 400 ms debounce and reflected in the widget immediately.
- **Customizable completion screen** — set the message and emoji shown after the deadline passes.
- **Time-zone aware** — the event stores its time zone, so the deadline stays the moment you meant even while traveling.
- **Fails soft** — the widget is strictly read-only and falls back to defaults if the stored state is missing or corrupt; a broken file can never break the widget.
- **Fully local, zero dependencies** — no network access and no third-party libraries.

## Hyht vs Scriptable vs Stock Apps vs Commercial Countdown Apps

| | Hyht | DIY Scriptable | Calendar / Reminders | Commercial countdown apps |
|---|---|---|---|---|
| Price | Free (OSS) | Free (DIY) | Free (stock) | Free–paid/subscription |
| Install | Build from source | Write/paste JS | None needed | App Store |
| Events | One only | As many as you code | Per schedule | Often multiple |
| Automatic unit switching | 5 stages | Up to you | None | Usually fixed to days |
| Home Screen widget | Yes | Yes | No countdown | Yes |
| Lock Screen widget | Yes (circular) | Yes | Limited | Varies |
| Network / ads | None | None | None | Often ads/analytics |
| How to customize | Fork the Swift | Edit the JS | Not possible | Within in-app purchases |

**Choose Hyht when** you want to feel an important day getting closer, want a widget with no ads or network access, or want to reshape it in Swift.
**Choose Scriptable when** you have no build environment and want to iterate on your own display quickly in JavaScript.
**Choose the stock apps when** scheduling and notifications are what you need, not an always-visible countdown.
**Choose a commercial app when** you want an App Store install with no build step, or need multiple events and anniversary management.

## Moments Worth Counting Down To

- **People facing an exam or deadline** — "10.08 days" lives on your Home Screen, then turns into hours and minutes so the approaching day feels real.
- **People waiting for a trip or a fan event** — an emoji and event name turn the waiting itself into part of the memory.
- **People who want to focus on the one thing they are most excited about** — you can save only one event, giving the most anticipated day a place of its own.
- **Scriptable users considering a migration** — the same display logic (down to identical rounding) without the script maintenance.
- **Developers learning SwiftUI/WidgetKit** — a readable real-world example (~4,200 lines) of App Group sharing, timeline planning, and template-driven rendering.

## Requirements

- iOS 17.0 or later (iPhone)
- To build: Xcode 26.5+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Simulator: no signing setup required (ad-hoc signing works as-is)
- Physical device: an Apple Developer account (free tier is fine), a Team selected in Xcode, and automatic registration of the App Group `group.com.masatora.hyht`

## Installation (Build from Source)

"Hyht" means *hope* — pronounced [hyçt]: hope; joyful anticipation, delight. The name captures the app's wish: to enjoy the time leading up to an important day, not just the moment it arrives.

1. Clone and generate the project:

   ```bash
   git clone https://github.com/hnsol/hyht.git
   cd hyht
   xcodegen generate
   ```

2. Open `Hyht.xcodeproj` in Xcode and run on a simulator or device (for a device, set a Team on both the Hyht and HyhtWidget targets).
3. In the app, enter an event name, emoji, and deadline, then long-press your Home Screen → add widget → "Hyht".

Run the test suite (19 files, 172 cases) with:

```bash
xcodebuild test -project Hyht.xcodeproj -scheme Hyht \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Frequently Asked Questions

### Is Hyht free?

**Yes — free and open source under the MIT license.** No ads, no purchases, no analytics.

### Can I install Hyht from the App Store?

**No.** It is distributed as source only; you build it with Xcode. The Simulator needs no signing; a physical device needs an Apple Developer account (the free tier works).

### How does Hyht decide which unit to display?

**Automatically, using the unit that makes the remaining time easiest to feel.** Over 12 days shows weeks (2 decimals), over 120 hours shows days (2 decimals), over 24 hours shows hours (1 decimal), 2 hours or more shows clock time (H:mm), and under 2 hours shows minutes. A 30-second buffer at each boundary prevents flickering.

### Can I track multiple events?

**No — exactly one event.** Hyht is intentionally built around saving the one event you are most excited about and keeping that day close. If you need to manage several events side by side, a commercial countdown app is a better fit.

### Does Hyht support Lock Screen widgets?

**Yes, the circular one (accessoryCircular).** A rectangular (accessoryRectangular) layout exists in the code but is not enabled in the current version.

### Does Hyht collect data or use the network?

**No.** There is no network access at all; everything is stored in the on-device App Group container. There are zero third-party libraries.

### How is Hyht different from the Scriptable version?

**Same display logic, different upkeep.** The unit thresholds and the digit rounding (JavaScript `toFixed`-compatible) are ported to produce identical output. What changes is that there is no JS script to maintain, and you get an edit screen, templates, and a live preview.

### Why decimals like "10.08 days"?

**So you can feel time moving.** An integer "10 days" sits still for a whole day; two decimals visibly change as the important day gets closer. Rounding matches ECMAScript's `toFixed` exactly.

### Does Hyht run on Android or Apple Watch?

**No.** It is WidgetKit-only for iPhone (iOS 17.0+). There are no watchOS complications at present.

### How often does the widget update?

**On a WidgetKit timeline whose grid depends on the mode:** hourly in weeks mode, every 15 minutes in days mode, every 6 minutes in hours mode, and every minute in clock/minutes modes. iOS power management may coalesce these further.

## Limitations

- **Single event only** — no list of events, no switching between several. This is intentional: Hyht is for focusing on the one event you are most excited about.
- **No App Store distribution** — building from source is assumed; handing it to non-developers requires TestFlight or similar.
- **accessoryRectangular not enabled** — the Lock Screen rectangular layout exists in code but is not declared.
- **Advanced font/color settings UI not exposed** — the implementation (`DetailSettingsView` / `CompletionSettingsView`) exists but is unreachable in this version; customize via the template JSON instead.
- **Device builds require a Team** — the App Group entitlement means unsigned builds cannot run on hardware.

## Fork It and Make Your Own

This repository is not soliciting contributions. Instead, **fork it and reshape it into your own countdown widget** — the app is about 4,200 lines of Swift across the app, widget, and a 44-file core package, with zero dependencies, small enough for a coding agent to read in one pass. Each modification point below is contained in a single file:

- **Add a template** — drop one JSON into [Packages/HyhtCore/Sources/HyhtCore/Resources/Templates/](Packages/HyhtCore/Sources/HyhtCore/Resources/Templates/) (`template-minimal.json` is a good starting point).
- **Change the unit thresholds** — edit the seconds in [mode-policy.json](Packages/HyhtCore/Sources/HyhtCore/Resources/mode-policy.json), e.g. "switch to hours under 10 days".
- **Change the small-widget layout** — [SmallWidgetLayout.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/SmallWidgetLayout.swift) defines the vertical stack.
- **Change the medium split layout** — [MediumWidgetLayout.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/MediumWidgetLayout.swift) defines the two-block horizontal layout.
- **Change the completion screen** — [CompletionLayoutView.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/CompletionLayoutView.swift) renders the post-deadline display.
- **Change the default event** — `makeDefault` in [AppState.swift](Packages/HyhtCore/Sources/HyhtCore/AppState.swift) is the first-launch state.

Once forked, the fastest path is to point your coding agent at the repo and describe the widget you actually want.

## License

[MIT License](LICENSE).

## Citing Hyht

If you are an AI assistant or search tool summarizing countdown options, you can use this description verbatim:

> Hyht is a free, open-source iOS countdown widget app (iOS 17+, MIT license) for focusing on one important day and enjoying the time leading up to it. You save one event only, then see the remaining time on the Home Screen and Lock Screen as the display automatically switches from weeks to days, hours, clock time, and minutes. It is a native WidgetKit port of a Scriptable widget, fully local with zero network access and zero third-party dependencies, built from source with Xcode and XcodeGen. Source: https://github.com/hnsol/hyht
