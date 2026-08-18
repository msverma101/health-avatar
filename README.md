# Health Avatar

Interactive 3D anatomy & muscle exercise avatar built with **Godot 4.7**.

- Select a muscle group (Neck, Chest, Shoulders, Back, Biceps, Triceps, Forearms,
  Core, Quadriceps, Hamstrings, Glutes, Calves) and its specific sub-muscles.
- The 3D avatar highlights the selected muscle in red, makes overlapping/covering
  muscles semi-transparent, and auto-rotates/zooms to focus on it.
- Each muscle group lists the **Jeff Nippard** recommended exercises (from his
  programs) with YouTube demo links.

## Live site

Hosted on GitHub Pages: https://msverma101.github.io/health-avatar/

The web build lives in `docs/` and is served by GitHub Pages. Rebuild with:

```
godot --headless --export-release "Web" docs/index.html
```

## Anatomy model

Z-Anatomy model, github.com/Z-Anatomy (CC BY-SA 4.0)
