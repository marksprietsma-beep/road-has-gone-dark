# Cross-platform verification and review build

Implementation SHA: `bfbdf48b4ae26dd1fc516cd8641177ee63fc4bd5`.

The final source run is [37599062997](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997): **completed, success** on both platforms. GitHub run metadata, job steps, artifact metadata and native-proof annotations were independently read after completion. Final commits update documentation only; the implementation remains the exact tested SHA above.

| Platform | Job | Full regressions | Native distribution |
| --- | --- | --- | --- |
| Windows | [112718693004](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/job/112718693004) | Passed | 60 checks, zero failures |
| Linux | [112718693254](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/job/112718693254) | Passed, including actual input/render | 60 checks, zero failures |

Both native runs exercised two presets and one fresh generated world with an empty PATH and no source-helper override. The isolated release lifecycle and production release launch passed. [Windows proof](windows-native-proof.json) and [Linux proof](linux-native-proof.json) record executable hashes, runtime pins and native results.

## Complete review artifacts

| Artifact | ID / download | GitHub artifact ZIP SHA-256 |
| --- | --- | --- |
| game83-complete-Windows | [11473119406](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11473119406) | `4ad9bfde7760b2ed08000a37431d0b8b4c7b363a84a70d27b1fa688f51638318` |
| game83-complete-Linux | [11473765159](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11473765159) | `dc4ee0f3635703b56e8b3ae41b25660aa05ac478f5505c6ffd865389fa55325e` |
| game83-qa-Windows | [11473523773](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11473523773) | `0c378abf91f9dfc1f6bdd8faf7fbd474390b1d32cb8bb741a118506b2722d27a` |
| game83-qa-Linux | [11472599735](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11472599735) | `18b921dfe45996b533f51026799a7dfa3d2202cb9bd4900c9f0af566b97307d2` |

The outer GitHub artifact ZIP and its inner application archive are different files. The native producer recorded these **inner archive** checksums:

```text
6ccb4032f7c18b5ab6fa5f7a291a1acea42de4cf2081000436e749039331e850  game83-windows-x64.zip
c15b4b59059a8880159e1003bc7792c344ab0f21927c37630cc6429d580b91e4  game83-linux-x64.tar.gz
```

The complete Windows artifact is named `game83-complete-Windows`. It contains the application, matching offline helper and checksums. Extract the artifact, then its inner game archive, keeping the helper beside the executable. No separately installed Node or Godot is required.

Sign in to GitHub and use the Windows artifact link above, or open the run's Artifacts section. Review steps are in [README.md](README.md#Windows-review). The artifacts currently expire on 2027-01-05; source, captures, proof records and build scripts remain committed.

[ci-run.json](ci-run.json) and [ci-artifacts.json](ci-artifacts.json) preserve the verified GitHub metadata. Direct redirected blob/log downloads returned HTTP 403 in this cloud workspace, so the binaries were not independently re-downloaded here. Their actual Windows/Linux execution was verified from successful CI jobs and native-proof annotations. The authenticated GitHub artifact links are the review delivery.

The earlier run 37563269371 passed Windows and native packaging but failed the reproduced Linux Back assertion. It is superseded, not the final review build. Intermediate runs 37598570153 and 37598913776 were cancelled after small visual-review corrections; they are not claimed as successful verification.
