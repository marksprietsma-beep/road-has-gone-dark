# GAME-61: provisional moving-time scenarios

P remains the developer-only route preview. While it is open, `]` steps through
unset → 15 → 30 → 60 minutes per open-hex effort; `[` steps back and `0` clears
the assumption. Values clamp at either end. Timing is session-only, starts
unset and resets with a region change. Actual gameplay ignores these controls.

The pure scenario calculation multiplies the route's provisional terrain
effort by the chosen minutes-per-effort value. Displayed moving time rounds up
to the next five minutes; the raw calculation remains available for validation.
The display is prefixed with `~` and labels both the scenario and its assumption.
It does not assign kilometres, total journey time, rest allowance or crossing
delays. A route overlapping an approximate river still has an unknown crossing
delay and may be impossible. Within-hex motion remains unknown rather than
being presented as instantaneous. Blocked routes have no estimate.

For Kindum → Old Toll House (6.875 effort):

| Assumed minutes per open-hex effort | Rounded moving time |
| ---: | --- |
| 15 | ~1h 45m |
| 30 | ~3h 30m |
| 60 | ~6h 55m |

These are pacing scenarios, not canonical times. The original world/local
source-space scale, shared Game-icons and route geometry stay unchanged.
No field on the generated route, source context or expedition session is
mutated. The source route layer continues to say hours/km are UNCALIBRATED.

The normal `.svg` and `.route.svg` retain their existing uncalibrated views.
The separately named `.timing.svg` is a labelled 30-minute scenario for review.
Its compact moving-time panel sits near the bottom so the top route caption
does not grow over source burgs. All six SVG examples were rasterised and
visually inspected; Ris displays unavailable time because it has no known
destination. Native screenshot evidence is not claimed.

Validation covers 48 known-route/preset combinations and guard cases, exact
native/SVG parity using JSON-normalised numeric fixtures, up-rounding and
formatting, unknown crossing delays, blocked/within-hex/unset estimates,
invalid preset/effort rejection, no generated/source mutation, hidden label
privacy, native enabled draw frames, preset clamping, region reset and disabled
gameplay controls. Existing route, contextual-site and expedition checks pass.
The native capture helper supports `-- --timing-review` with a display.

Next useful prototype: compare an out-and-back journey against a chosen
daylight budget, while keeping rests, investigation and crossing knowledge
explicit rather than hiding them in a claimed arrival time.

Work remains local; branch publication awaits explicit approval.
