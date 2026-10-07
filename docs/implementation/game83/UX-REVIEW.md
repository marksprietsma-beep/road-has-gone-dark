# Screen-by-screen review

This is an engineering review of actual Godot captures and input runs, not a timed usability study. The “two seconds” goal remains a question for Mark's Windows review. The shared vocabulary is black background, parchment body copy, gold headings/selection/primary action, and subdued metadata. No new facts, mechanics or rewards were added.

| Screen | Primary action / context | Density, navigation and remaining compromise |
| --- | --- | --- |
| Main menu | New Game; existing validated campaign resume when available | Compact centred controls. Resume wording still comes from the actual saved campaign stage. |
| World | Choose a library entry, then Next | Player names and map retain existing factual content. Generation/library controls retain their existing behavior. |
| State | Select a state, then Next | Political list gains rows on larger windows; focus and selection are distinct. Gold place heading, parchment profile, dimmer facts. |
| Region | Select the actual source area, then Next | Same list/map/details arrangement. Back preserves valid upstream choices. |
| Hometown | Select a small hometown, then Next | Compact shortlist reserves space for public memory/tradition. Late selection is revealed after Back and live resizing. Long profiles scroll at 640×360. |
| Confirm | Confirm origin | Location and facts remain visible with map context. Navigation remains outside the scroll areas; no save is created by browsing. |
| Party creation | Edit a member; Party ready | Three two-line roster entries show name plus ancestry/role. Compact identity fields and a separate Background tab reduce competition. Save character remains secondary. |
| Party ready | Enter hometown | Background opens by default. Editing controls are hidden; no unavailable reroll bar. The reading column is bounded on large displays. |
| Hometown hub | Choose a local account | Shared selectable rows separate titles from status badges. Local accounts and recent events are composable sections for later screens. No facilities have been implemented. |
| Lead detail | Accept local lead / Begin expedition | Goal, issuer, clue and status are separated. Back to local leads is secondary. Long details still scroll on the smallest window. |
| Local map | Scout or travel according to actual knowledge | Terrain is no longer covered by decorative houses or numbered blocks. A rumoured site has no marker. Costs remain the original GAME-84 values. |
| Site | Choose an investigation approach, or leave | Existing consequences and costs only. Focus-follow scrolling reveals lower choices; the map and footer remain visible. |
| Result | Read What changed, then Return to hometown | Opens at the heading instead of inheriting the choices' scroll offset. Investigation status and the persisted consequence are explicit. Long results may scroll at 640×360. |
| Returned hometown | Choose another account | Completed status and recent events reflect the original saved state. Focus returns to a visible row, not the now-hidden return button. |
| Resume / Continue | Resume the actual campaign phase | The real menu and scene transitions restore the consequence/expedition state. No save-browser redesign. |

## Maps and input

The house with a small party pennant combines hometown and party position. Known sites are compact diamonds; selection/focus has a gold outline. The footer explicitly says where the party is. Public tooltips and text selection retain names. Marker hit centres remain at the exact source-derived positions; hidden/rumoured sites do not acquire clickable markers before discovery.

Tab, Shift+Tab, arrows, Enter, Escape and mouse paths are exercised by the original and added Godot input tests. Focus remains visible after asynchronous saved transitions, including returning home. Primary footer navigation stays outside scrolling detail content. Dense or overlapping locations still have keyboard and named-list alternatives; no clustering system or geography change is included.

## Resolution review

640×360 is the constrained layout: all three party members, the main map and footer navigation remain usable, while long source profiles and site choices can scroll. At 1280×720 and 2560×1440 the logical canvas grows, rather than quadrupling every control. Map area and political lists gain space, while the party reading width remains bounded. Original full-resolution captures are linked in [SCREENSHOTS.md](SCREENSHOTS.md).

Windows native execution is tested separately from these Linux software-GL captures. Mark should still assess laptop display scaling, reading comfort and the speed of recognising the next action. Existing generated prose can be repetitive; this presentation pass deliberately does not rewrite content generation.
