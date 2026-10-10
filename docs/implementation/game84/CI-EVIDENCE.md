# Final CI and native distribution evidence

[Verified Actions run](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837) — **success**, implementation `1c9d00d0744259f8f8d37a03fcd3c6122a534904`. Windows and Linux source/regression jobs and native packaging passed. Final evidence-only commits retain this exact executable source.

| Job | Status | Native checks |
| --- | --- | --- |
| [party (windows-latest)](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/job/112429494509) | success | 60 checks / zero failures |
| [party (ubuntu-latest)](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/job/112429494971) | success | 60 checks / zero failures |

The native diagnostic export executed the full loop on both packed presets and one newly generated world, with PATH empty and no source helper override. The production release executable also launched successfully. Four compatible runtime manifests are pinned in [machine-readable proof](distribution-proof.json).

| Download | GitHub artifact container size |
| --- | --- |
| [game84-complete-Linux](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/artifacts/11436570667) | 125,561,138 bytes |
| [game84-complete-Windows](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/artifacts/11436272712) | 114,858,766 bytes |
| [game84-qa-Linux](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/artifacts/11436165887) | 11,198,093 bytes |
| [game84-qa-Windows](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837/artifacts/11436043031) | 222,639 bytes |

GitHub artifacts have retention limits; their recorded expiration and outer container digests are in the machine-readable proof. Source and reproduction scripts are committed. The complete artifact contains the inner native archive, checksum and matching single helper. Extract both archive layers completely.

## Native archive SHA-256

`game84-windows-x64.zip`

```text
14a3326e5eaf615fa72866ccbd25e1b9e69fed197186e570cd4b3fddf5f923a7
```

`game84-linux-x64.tar.gz`

```text
2bb4a3c7275cf8b6bff681cfd0b0e928c5b19322d188a3cf5dd775d83cc5552b
```

These are the inner native archive checksums, not GitHub’s outer artifact-container digests. The checksum evidence is taken from executed native proof annotations, independently matched to successful job/run/commit metadata. Redirected artifact/log blobs are inaccessible to this environment; we do not claim an extra local redownload/re-hash of those blobs.

The local `logs/native-distribution-development.txt` records an earlier Linux development export. The final review archives and their authoritative proofs are the exact CI source shown above. Native headless Windows execution is not human laptop visual acceptance. Follow [Windows review steps](README.md#windows-review-steps), including full quit/restart and a second campaign.
