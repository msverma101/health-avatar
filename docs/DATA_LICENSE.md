# Exercise Motion Data — Provenance & License

This document records where the exercise motion data in this project comes from
and its legal status.

## Source: MM-Fit dataset

- **Project page:** https://mmfit.github.io/
- **Paper:** Strömbäck, Huang, Radu. *"MM-Fit: Multimodal Deep Learning for
  Automatic Exercise Logging across Sensing Devices."* Proc. ACM Interact. Mob.
  Wearable Ubiquitous Technol. 4, 4, Article 168 (December 2020).
  DOI: https://doi.org/10.1145/3432701
- **Starter code (MIT):** https://github.com/KDMStromback/mm-fit
- **Data download:** direct S3 archive (`mm-fit.zip`), ~1.7 GB
- **Format:** per-workout `.npy` arrays of 2D/3D skeleton joints + CSV labels
  `(start_frame, end_frame, reps, exercise)` for 20 workout sessions covering
  squats, push-ups, shoulder press, lunges, rows, sit-ups, tricep extensions,
  bicep curls, lateral raises, and jumping jacks.

## License status — ⚠️ PROTOTYPE / DEVELOPMENT USE ONLY

The MM-Fit dataset ships **without a data license file**. We verified the full
archive's file listing (324 entries): there is **no LICENSE, README, or terms
file** for the dataset itself. The accompanying paper carries only the ACM
copyright notice, which restricts copies "distributed for profit or commercial
advantage" and requires "prior specific permission" for redistribution.

Consequences:

- The code repo (`KDMStromback/mm-fit`) is **MIT** — safe.
- The **dataset** has **no explicit license**, so no commercial rights are
  granted. Using it in a commercial product is **legally risky**.
- In this project the motion data (`data/exercises/*.json`) is used to drive a
  prototype avatar animation. It must **not ship in a commercial release** until
  either:
  1. We obtain a written commercial license from the MM-Fit authors, or
  2. We replace the data with a permissively-licensed source (e.g. CMU Motion
     Capture Database, which is explicitly free for all uses including
     commercial products).

## Extracted data in this project

`data/exercises/squat.json` contains per-frame joint-flexion angles extracted
from the MM-Fit `w00` workout (first squat set, frames 4040–4500). The values
are smoothed joint angles (knee/hip flexion per leg, torso lean) used to drive
the avatar's bones.

## Alternatives for shipping

- **CMU Motion Capture Database** (mocap.cs.cmu.edu): "free for all uses",
  may be included in commercially-sold products (may not resell raw data).
  Sparse exercise coverage (squats, jumping jacks, acrobatics).
- **Mixamo** (Adobe): unlimited commercial use, rich exercise library, but not
  open-source and raw files cannot be redistributed.
