# The Road Has Gone Dark

A Godot 4 project for a retro dark-fantasy game.

## Intro sequence

The project starts with a reusable, data-driven intro sequence. Edit
`data/intro/intro_cards.json` to change, add, or remove cards without changing
the scene or controller. Each card accepts a `body`, an optional `title`, and an
optional `display_duration` value reserved for future automatic pacing.

Press Space, Enter, or the left mouse button to advance. Press Escape to skip
to the temporary end screen. The presentation theme is stored separately at
`themes/intro_theme.tres`, so a licensed pixel font can be assigned later
without changing the controller.
