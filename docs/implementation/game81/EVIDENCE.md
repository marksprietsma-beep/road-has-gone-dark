# Actual Godot review frames

These are viewport captures from Godot 4.6.3's compatibility renderer, driven through real keyboard/mouse input. Linux llvmpipe/Xvfb supplies the local rendering evidence; native Windows automated package QA and Mark's laptop visual acceptance are separate. Full logs and assertions are reproduced by `tests/party/run-tests.py --visual`.

The sequential set follows Main menu → New Game → origin confirmation → three adventurers → people selection → edited name → one-member reroll → neighbouring members → Party Ready → menu/resume. The generated-world frames use a genuine newly generated Azgaar world, not a preset relabelled as generated.

[Mobile gallery](gallery.html).

| View | Actual frame |
|---|---|
| Main menu | [Frame](screenshots/main-menu.png) |
| Origin confirmation | [Frame](screenshots/origin-confirmation.png) |
| 640×360 party overview | [Frame](screenshots/party-overview-640x360.png) |
| 640×360 biography | [Frame](screenshots/background-640x360.png) |
| 1280×720 party overview | [Frame](screenshots/party-overview-1280x720.png) |
| 2560×1440 party overview | [Frame](screenshots/party-overview-2560x1440.png) |
| All eight people choices | [Frame](screenshots/people-popup-2560x1440.png) |
| Edited name | [Frame](screenshots/edited-name-2560x1440.png) |
| Deliberately regenerated background | [Frame](screenshots/regenerated-background-2560x1440.png) |
| Second member | [Frame](screenshots/second-background-2560x1440.png) |
| Third member | [Frame](screenshots/third-background-2560x1440.png) |
| Party Ready | [Frame](screenshots/party-ready-2560x1440.png) |
| Menu resume | [Frame](screenshots/main-menu-resume-party.png) |
| Resumed exact Party Ready | [Frame](screenshots/resumed-party-ready.png) |
| Fresh-world party | [Frame](screenshots/fresh-world-party-2560x1440.png) |
| Fresh-world biography | [Frame](screenshots/fresh-world-background-2560x1440.png) |

The compact original layout exposed footer overflow during QA; the final overview/body heights now leave the footer accessible at 640×360. Biographies and people descriptions scroll within bounded panels. An immutable local-presence cache keeps list/dropdown interaction from repeatedly validating the entire world; saving still performs the strict full persistence validation.
