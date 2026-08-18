# Health Avatar App — Project Brief

## Overview

Build a cross-platform mobile app in Godot 4 for Android and iOS.

The app is an interactive 3D human anatomy and exercise education tool. Users should be able to rotate a human model, select muscles, learn about them, see relevant exercises, and watch the avatar demonstrate those exercises.

The app should eventually import activity data from existing services such as Apple Health, Android Health Connect, Strava, Hevy, and compatible watches. It should explain that activity visually instead of becoming another manual workout tracker.

## Product decisions

- Use Godot as the main application framework.
- Do not use React or a hybrid architecture unless Godot becomes technically impossible.
- Do not build computer vision yet.
- Do not build manual workout logging.
- Do not add user accounts, cloud sync, or wearable integrations in the first milestone.
- Develop and test on Ubuntu first, especially Android.
- iOS export can be handled later using macOS and Xcode.
- Prefer free and open-source tools where possible.
- Use only properly licensed or self-created 3D models, videos, images, and data.
- Do not make medical diagnosis claims.

## Intended architecture

Keep external integrations separate from the 3D avatar and interface.

```text
External source
    ↓
Source adapter
    ↓
Normalized activity data
    ↓
Exercise and muscle mapping
    ↓
Avatar state and explanations
```

Possible future adapters:

- Apple HealthKit
- Android Health Connect
- Strava
- Hevy
- Garmin, Fitbit, Oura, and other watch platforms where supported

The avatar must not directly depend on Strava, Hevy, or any single data source.

## Suggested domain models

- `Muscle`
- `MuscleGroup`
- `Exercise`
- `EquipmentOption`
- `Activity`
- `MuscleActivation`
- `RecoveryEstimate`
- `SourceReference`

## First milestone: runnable prototype

Build a small working prototype rather than the complete application.

The prototype should include:

1. A Godot project that runs on Ubuntu.
2. A placeholder or properly licensed 3D human model.
3. Orbit rotation, zoom, and mouse/touch interaction.
4. Five clickable muscle groups.
5. A selected-muscle information panel.
6. A small exercise list for each selected muscle.
7. At least one simple exercise animation, or a clearly marked animation placeholder.
8. A data-driven JSON or Godot Resource content model.
9. A sample imported activity dataset.
10. No manual workout logger.
11. A basic visual state system:
    - green = no recent activity
    - orange = recently involved
    - red = high estimated load
12. Clear separation between the 3D scene, UI, anatomy data, exercise data, activity data, and mapping/recovery logic.

Use sample JSON data instead of real HealthKit, Health Connect, Strava, or Hevy integrations during this milestone.

## Suggested project structure

```text
health-avatar-app/
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── anatomy_view.tscn
│   └── exercise_view.tscn
├── scripts/
│   ├── app_controller.gd
│   ├── anatomy_controller.gd
│   ├── activity_mapper.gd
│   └── recovery_estimator.gd
├── data/
│   ├── muscles.json
│   ├── exercises.json
│   └── sample_activities.json
├── assets/
│   ├── models/
│   ├── animations/
│   └── icons/
├── ui/
└── docs/
```

## Instructions for the next agent

Before implementing:

- Inspect the workspace.
- Confirm the installed Godot version and available Android tooling.
- Propose any changes to the folder structure.
- Explain the temporary or licensed model strategy.
- Identify any missing assets or dependencies.

Then create the smallest runnable prototype and test it on Ubuntu.

Explain major architectural decisions and keep the implementation easy to extend.

Do not:

- Add computer vision.
- Add user accounts.
- Add cloud sync.
- Add wearable integrations yet.
- Add a manual workout logger.
- Add medical diagnosis features.
- Invent scientific muscle mappings without references.
- Replace Godot with React without clearly explaining the blocker.

The first deliverable is a runnable Godot prototype with a clean foundation for future integrations.
