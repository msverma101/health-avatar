# Third-Party Assets & Licenses

This document records the provenance and license of every third-party asset in
this project. Only assets listed here may be distributed with the app.

## 3D model: body.glb (anatomy atlas)

- **Path:** `assets/models/body.glb`
- **Source model:** [Z-Anatomy](https://www.z-anatomy.com/) — "The libre 3D atlas of anatomy"
  - GitHub: https://github.com/Z-Anatomy (project by Gauthier Kervyn and Marcin Zielinski)
  - License: **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)** — https://creativecommons.org/licenses/by-sa/4.0/
- **Underlying data:** BodyParts3D (Database Center for Life Science), **CC BY-SA 2.1 Japan** — https://dbarchive.biosciencedbc.jp/en/bodyparts3d/download.html
- **Processed GLB:** [hpfrei/body-anatomy-3d-viewer](https://github.com/hpfrei/body-anatomy-3d-viewer)
  - Simplified geometry, DRACO compression, embedded structure metadata
  - License: **CC BY-SA 4.0** (Copyright 2026, hpfrei)

### Attribution notice

The 3D anatomy model used in this app is derived from the Z-Anatomy project
(CC BY-SA 4.0) and BodyParts3D (CC BY-SA 2.1 Japan). When this app is
distributed, this notice and license record must be included.

### Permitted uses

- Free to share and adapt, including for commercial purposes.
- Attribution required (this file satisfies that requirement).
- **ShareAlike:** any remix/derivative of the model data must be distributed
  under the same (or compatible) license.

### What this means for the app

- The app itself (code, UI, procedural parts) is NOT placed under CC BY-SA;
  only the model file and its derivatives are covered by the model's terms.
- Attribution to Z-Anatomy / BodyParts3D / hpfrei is preserved here and
  should be surfaced in the app's "About / Credits" screen.
