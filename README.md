# Retirement Countdown

A native iOS + Apple Watch app that shows how many days remain until your retirement date. Count total calendar days or Mon–Fri workdays (excluding US federal holidays). The count is displayed across the iPhone app, Home Screen / StandBy widgets, Lock Screen widgets, the Apple Watch app, and watch face complications.

## Surfaces

| Surface | Details |
|---|---|
| iPhone app | Full-screen day count, inline mode toggle (All days / Workdays), edit date |
| iOS Home Screen widget | Small / Medium / Large |
| iOS Lock Screen widget | Inline / Circular / Rectangular |
| StandBy | Uses the small widget |
| Watch app | Day count + date, updates via WatchConnectivity |
| Watch complications | Inline / Circular / Rectangular / Corner (Smart Stack too) |

## Requirements

- Xcode 16+
- iOS 17+ / watchOS 10+
- Swift 5.9+
- No third-party dependencies

## Architecture

The iPhone is the source of truth. The retirement date lives in shared App Group storage; every widget and the watch pull from that same store. Cross-device sync uses `WCSession.updateApplicationContext` (latest-revision-wins).

```
┌─────────────────┐        WCSession        ┌─────────────────┐
│   iPhone App    │ ──────────────────────► │    Watch App    │
│   (source of    │                         │  (last-known    │
│    truth)       │                         │   cache)        │
└────────┬────────┘                         └────────┬────────┘
         │                                           │
         ▼                                           ▼
┌─────────────────┐                         ┌─────────────────┐
│  App Group      │                         │  App Group      │
│  (iOS side)     │                         │  (watchOS side) │
└────────┬────────┘                         └────────┬────────┘
         │                                           │
         ▼                                           ▼
┌─────────────────┐                         ┌─────────────────┐
│  iOS Widgets    │                         │  Watch Widgets  │
│  (system +      │                         │  (complications)│
│   accessory)    │                         │                 │
└─────────────────┘                         └─────────────────┘
```

Both devices share App Group `group.ghiassy.retirement-countdown`.

## Project Layout

```
retirement-countdown/
├── CountdownCore/                          Local Swift Package — pure logic, no framework deps
│   ├── Package.swift
│   ├── Sources/CountdownCore/
│   │   ├── RetirementDate.swift            YYYY-MM-DD codec + Gregorian validation
│   │   ├── RetirementRecord.swift          Persisted envelope (date + revision + schema)
│   │   ├── CountdownMode.swift             .calendarDays | .workdays
│   │   ├── CountdownCalculator.swift       Pure day-count logic, DST-safe
│   │   ├── USFederalHolidays.swift         11 US federal holidays with observed-weekend rules
│   │   ├── CountdownDisplayModel.swift     Display-ready enum with factory
│   │   └── CountdownFormatter.swift        Number / date / accessibility strings
│   └── Tests/CountdownCoreTests/           57 unit tests
├── retirement-countdown/                   iOS app target
├── retirement-countdownWidget/             iOS WidgetKit extension
├── retirement-countdownWatch Watch App/    watchOS app target
└── retirement-countdownWatchWidget/        watchOS WidgetKit extension
```

## Key Design Choices

- **Date stored as a YYYY-MM-DD string, never a UTC timestamp.** Time-zone travel doesn't shift the retirement date.
- **Day math uses `Calendar.dateComponents([.day], from:to:)`, never `86400s` division.** DST transitions can't produce off-by-one errors.
- **US federal holidays are computed, not hard-coded.** 5 fixed-date holidays apply the observed rule (Sat→Fri, Sun→Mon); 6 nth-weekday holidays (MLK, Presidents, Memorial, Labor, Columbus, Thanksgiving) use `DateComponents.weekdayOrdinal`. Juneteenth is included only for years ≥ 2021.
- **State (unconfigured / counting / today / retired) is always based on the calendar date comparison.** The mode only affects the number shown inside the counting state; the state transition happens at the retirement date regardless of mode.
- **Mode is a per-preference App Group key**, synced to the watch on every WCSession payload. Toggling mode on iPhone reflects on all surfaces within a widget-timeline refresh cycle.
- **Watch app is a companion of the iPhone app** (`WKCompanionAppBundleIdentifier = ghiassy.retirement-countdown`), not a watch-only app. WCSession only routes messages when this pairing is recognized.

## Building

Open `retirement-countdown.xcodeproj` in Xcode, select the `retirement-countdown` scheme, and run to an iPhone with a paired Apple Watch. Widgets and complications need to be added manually the first time via the Home Screen widget picker and the watch face Edit → Complications flow.

## Tests

The `CountdownCore` package has 57 unit tests covering date validation, DST edge cases, leap days, workday counting, and holiday observance rules.

```
swift test --package-path CountdownCore
```

## App Group

All four targets have App Group entitlement `group.ghiassy.retirement-countdown`. If you fork this project, update the group ID everywhere in `retirement-countdown.xcodeproj` and in the four `*.entitlements` files.
