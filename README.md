# openccu-lite-base

[OpenCCU-Base](https://github.com/OpenCCU/OpenCCU-Base) cut down to the paths that
[openccu-lite](https://github.com/hobbyquaker/openccu-lite) builds from: the Homematic radio
stack's daemons and libraries, the device types, the firmware files and the HMServer/HmIP Java
side. The original WebUI and ReGaHss are part of OpenCCU-Base too, and most of its commits change
them. openccu-lite ships neither, so they are filtered out here, together with the commits that
only touched them. What is left is OpenCCU-Base's own history of the parts openccu-lite uses,
commit by commit.

This is not a fork and nothing here is changed by hand. Every commit on `upstream` is an
OpenCCU-Base commit, filtered by a script: same author, same date, same message, with one line
added at the end that links to the original:

```
Upstream: https://github.com/OpenCCU/OpenCCU-Base/commit/<full commit id>
```

Report bugs and send changes to [OpenCCU-Base](https://github.com/OpenCCU/OpenCCU-Base), not here.

## Branches and tags

| Ref | Holds |
| --- | --- |
| `upstream` | OpenCCU-Base's `main`, filtered. Written only by the sync workflow; only ever moves forward. |
| `lite` | What openccu-lite builds from: upstream's releases, merged one by one, minus what openccu-lite reverted. Never written by a workflow. |
| tags `<version>-lite.<N>` (`3.89.11-lite.1`, ...) | The states of `lite` openccu-lite pins, numbered per upstream version. |
| tags (`3.89.11`, ...) | OpenCCU-Base's release tags with the same names, on the filtered commits. A tag whose commit was filtered out sits on the nearest older commit that was kept; the files under the kept paths are the same there. |
| `main` | This readme, [`paths.txt`](paths.txt), [`filter.sh`](filter.sh), [`merge-pr.sh`](merge-pr.sh) and the two workflows. |
| `meta` | `commit-map` (`<OpenCCU-Base id> <openccu-lite-base id>` per line; all zeros for a commit that was filtered out) and `ref-map`, written by every sync that changed something. |

## How it follows upstream

[`.github/workflows/sync.yml`](.github/workflows/sync.yml) runs every day and on demand. It
clones OpenCCU-Base's `main` with its tags completely, runs [`filter.sh`](filter.sh) over it
(`git filter-repo` with [`paths.txt`](paths.txt) and the commit callback that writes the
`Upstream:` line), and pushes `upstream` and any new tags. git-filter-repo is pinned by version
and checksum.

The filter is deterministic: the same history gives the same commit ids, and a longer history
gives a history that contains the shorter one unchanged. So a sync only ever adds commits on top.
The workflow refuses to push anything else, and fails loudly instead, if the new result does not
contain the published `upstream` branch or a published tag would move. That happens only when
`paths.txt` or `filter.sh` changed, or when OpenCCU-Base rewrote its own history. Either way it is
a new generation of this repository, decided and done by hand, never by the sync.

## The `lite` branch

openccu-lite does not build from `upstream` directly but from `lite`, so that an upstream release
reaches it only after a look at what it changes:

1. The sync brings a new release tag of OpenCCU-Base (say `3.89.12`) to `upstream`.
2. [`.github/workflows/merge-pr.yml`](.github/workflows/merge-pr.yml) (after each sync, daily and on
   demand) opens a pull request **"Merge 3.89.12 into lite"** from a branch `merge/3.89.12` at the
   tag, with every new commit and its `Upstream:` link. It never pushes to `lite` itself, and opens
   a tag's pull request once; deleting the branch `merge/<tag>` has it opened again.
3. The maintainer reviews and merges it with a merge commit. A commit openccu-lite does not take is
   reverted on `lite` right after, with the reason in the revert's message.
4. `lite` gets the tag `3.89.12-lite.1`; a later change to the same base (another revert, a fix
   taken early with `git cherry-pick -x` from `upstream`) gets `-lite.2` and so on. openccu-lite's
   `openccu-base.mk` pins such a tag.

`lite` started at `3.89.11`; `3.89.11-lite.1` is that commit.

## What is kept

[`paths.txt`](paths.txt) is the list, with a reason for each line. In short: the CMake build
(`CMakeLists.txt`, `cmake/`, `build-tools/`), every component under `src/` except the WebUI and
three daemons openccu-lite does not ship (`hss_led`, `eq3configd`, `ssdpd`), the startup scripts
`bin/hm_autoconf`, `bin/hm_deldev` and `bin/hm_startup`, `etc/`, `firmware/`, hmipserver
(`opt/HMServer/HMIPServer.jar`, `opt/HMServer/coupling/`, `opt/HMServer/groups/`), `opt/HmIP/`
and `licenses/`.

Left out: the WebUI sources and the built WebUI (`src/webui/`, `www/`), `src/hss_led`,
`src/eq3configd` and `src/ssdpd`, `opt/HMServer/HMServer.jar` (the BidCos-only server
openccu-lite never starts), the WebUI's FreeMarker pages `opt/HMServer/pages/` and the diagrams'
`opt/HMServer/measurement/`, the prebuilt binaries and libraries under `bin/<platform>/` and
`lib/<platform>/` (ReGaHss among them; openccu-lite compiles the rest from `src/`), `usr/` (built
from `src/tcl_homematic`), OpenCCU-Base's own `.github/`, `tests/`, `Makefile`,
`CMakePresets.json`, `README.md` and `.gitignore`.

**One rewrite, on 2026-10-07:** the first published history (head `7a30437`, `3.89.11` at
`59850dc`, 508 commits) still had `src/webui/scripts/`, `src/hss_led`, `src/eq3configd`,
`src/ssdpd`, `HMServer.jar` and HMServer's pages and measurement templates, which openccu-lite
built or installed and then deleted from its image or never used. They were taken out the same
day, before anything built from this repository, and `upstream`, the tags, `lite` and `meta` were
replaced once. `paths.txt` is final since: a change to it would rewrite the history again, which the sync refuses.

## Licence

The licences are OpenCCU-Base's, unchanged, and the licence files under `licenses/` are kept:
eQ-3's software is under the HomeMatic Software License (`licenses/HMSL2.txt`), the kernel
modules under the GPL 2.0 and the libraries under the LGPL 2.1, as
[`licenses/licenses.md`](https://github.com/OpenCCU/OpenCCU-Base/blob/main/licenses/licenses.md)
in OpenCCU-Base lists them. The files on `main` (readme, path list, script, workflow) are under the
Apache License 2.0, like openccu-lite.
