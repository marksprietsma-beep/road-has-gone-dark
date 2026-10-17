# Genuine Windows Godot evidence

Download `game133-native-evidence` from the [exact release workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39047311816). Its `captures/screenshots.json` records each PNG SHA-256, fixture classification and earned-XP scope. These are actual exported Godot production scenes rendered on Windows, never generated artwork. The independent archive auditor checks PNG signatures, checksums and actual dimensions against filenames. Treat evidence as accepted only after the linked release run and archive audit succeed.

Expected captures:

- `earned-sorcerer-tier4-1280x720.png`
- `earned-druid-tier4-1280x720.png`
- `earned-advancement-no-free-xp-1280x720.png`
- `fixture-sorcerer-tier6-1280x720.png`
- `fixture-sorcerer-tier7-1280x720.png`
- `fixture-sorcerer-sheet-2560x1440.png`
- `fixture-druid-tier6-1280x720.png`
- `fixture-druid-tier7-1280x720.png`
- `fixture-druid-sheet-2560x1440.png`
- `fixture-hybrid-independent-tracks-1280x720.png`
- `fixture-packward-combat-1280x720.png`
- `fixture-packward-combat-small-640x360.png`
- `earned-midbattle-spells-saved-1280x720.png`
- `earned-midbattle-spell-log-2560x1440.png`

Earned captures use the real490XP/level8 campaign and its service-committed encounter fork. High-level render-only records are labelled DEVELOPMENT FIXTURE/not earned XP. Their companion IDs are remapped consistently and derived records validated before rendering. Screenshot overrides never change the earned campaign; the capture driver verifies original state/save equality afterward. No QA executable or XP button is shipped.
