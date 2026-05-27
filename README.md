# Carter's Games

A collection of touch-first mini-games for kids age 5–10, built in Godot 4 and deployed as a Progressive Web App (PWA). Playable on any modern browser — optimised for tablet.

**Live:** [itch.io](https://abroederdorf.itch.io/carters-games) · [Netlify](https://cartersgames.netlify.app)  
**Window size:** 1280×800 landscape  
**Renderer:** Mobile  

---

## Games

### Gone Fishin'
Tap-to-cast fishing game with math and spelling educational modes. Features multiple fish types, predators (shark, pelican, octopus), a timer, and a local leaderboard.

- Free Play, Math Mode, and Spelling Mode
- Difficulty levels affect fish speed and problem ranges
- Leaderboard saved locally per mode/difficulty/timer combination

### Find It! (Hide & Seek)
Where's Waldo-style hidden object game. Pan and zoom a busy illustrated scene and tap items from a thumbnail strip to find them. Scenes are data-driven — adding new scenes requires no code changes.

- 45 scenes planned, each with 15–20 items
- Star rating system (time-based), hint system using stars as currency
- Scene data stored in `resources/hide_seek/<scene>.tres`

→ [Scene pipeline guide](docs/hide-seek-pipeline.md)

### Morning Scramble *(in progress)*
House-exploration chore/puzzle mini-game. School theme, 7 rooms, 3 missing items to find before the bus arrives.

## Design & Accessibility

The games are designed specifically for children age 5–10, focusing on high-quality visual feedback and forgiving interaction patterns:

- **Visual Style:** Children's book illustrations with thick black outlines and vibrant colors for readability on mobile screens.
- **UI:** Illustrated buttons shared across all mini-games for a consistent experience.
- **Accessibility:** Slow animation speeds to allow for younger reaction times, large hit-zones on touch targets, and audio cues throughout.

---

## Project Structure

```
assets/
  audio/              — Sound effects and background music
  data/hide_seek/     — themes.json (all 45 scene definitions + item lists)
  icons/              — App icons and UI icons
  sprites/
    hide_seek/
      <scene_name>/   — Per-scene background + item PNGs/WebPs
      shared/         — Reusable items used across multiple scenes
    fishing/          — Fishing game sprites
    morning_scramble/ — Morning Scramble sprites

resources/hide_seek/
  <scene>.tres        — Main scene resource (background, items, anchors)
  <scene>/            — Individual HideSeekItemData resources

scenes/               — Godot .tscn scene files
scripts/
  hide_seek/
    automation/       — Python + GDScript pipeline tools (see below)
    core/             — Runtime game scripts
    editor/           — In-editor Scene Builder scripts
    resources/        — Resource class definitions

local/                — Local-only files, gitignored (plan docs, exports, credentials)
web/                  — Output directory for web export (gitignored content)
.github/workflows/    — CI/CD (export + deploy to Netlify)
```

---

## GitHub Actions

### Verify Hide & Seek Tags (automatic)

Runs automatically on every push to `main` and on pull requests that touch `resources/hide_seek/` or `verify_tags.py`. Validates that every item in every scene has at least one matching anchor tag — catches placement errors before they merge.

No secrets required.

### Export & Deploy (manual)

All deployments are manual and controlled. Trigger from the **Actions** tab → **Export & Deploy** → **Run workflow**, then pick a target:

| Target | What happens |
|--------|-------------|
| `itch` | Export → deploy to itch.io (use for testing) |
| `netlify` | Export → deploy to Netlify (use for releases) |
| `both` | Export once → deploy to both from the same build |

**Workflow:** `itch` and `netlify` are a single export job that uploads an artifact, then one or two deploy jobs that download and push it. This means if you pick `both`, Netlify gets the exact same binary you tested on itch.io.

**Typical flow:**
1. Work is merged and ready to test → run workflow → pick `itch`
2. Test on itch.io — looks good → run workflow → pick `both` to sync Netlify to the same build

Required GitHub secrets (repo Settings → Secrets and variables → Actions):
- `BUTLER_CREDENTIALS` — itch.io API key (from [itch.io account settings](https://itch.io/user/settings/api-keys))
- `NETLIFY_AUTH_TOKEN` — Netlify personal access token
- `NETLIFY_SITE_ID` — site ID from the Netlify dashboard

### Local web export

```bash
mkdir -p local/exports/html
godot --headless --export-release "Web" local/exports/html/index.html
```

Open via a local server — the PWA requires `SharedArrayBuffer`, which browsers only allow over HTTPS or localhost:

```bash
cd local/exports/html && python -m http.server 8080
# then open http://localhost:8080
```

---

## Git Workflow

Always work on a feature branch and open a PR — never commit directly to `main`.

```bash
git checkout -b feat/<description>
# ... make changes ...
git push origin feat/<description>
# Open PR on GitHub
```

