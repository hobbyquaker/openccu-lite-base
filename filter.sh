#!/bin/bash
# filter.sh <clone>: rewrite a fresh clone of OpenCCU-Base in place into openccu-lite-base's
# `upstream` history. The clone must hold upstream's `main` (and its tags) and nothing else.
#
# What it does, and nothing more:
#  - keeps only the paths in paths.txt (next to this script); everything else, upstream's own
#    .github/ included, leaves the history, and commits that touched only those paths go with it;
#  - appends the trailer "Upstream: https://github.com/OpenCCU/OpenCCU-Base/commit/<full hash>"
#    to every kept commit, naming the commit it was rewritten from;
#  - keeps authors, committers, dates and the rest of every message as upstream wrote them.
#
# The result is deterministic: the same upstream history, paths.txt and git-filter-repo version
# give the same commit ids, and a longer upstream history gives a history that contains the
# shorter one unchanged. The sync workflow depends on that to push fast-forward only.
set -euo pipefail

clone=${1:?usage: filter.sh <clone>}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
filter_repo=${GIT_FILTER_REPO:-git-filter-repo}

# The trailer goes into the message's last paragraph when that already is a trailer block
# (Signed-off-by:, Co-authored-by: ...), so git and GitHub still read those trailers; otherwise
# it starts a paragraph of its own.
callback='
import re
url = b"https://github.com/OpenCCU/OpenCCU-Base/commit/" + commit.original_id
msg = commit.message.rstrip(b"\n")
paragraphs = msg.split(b"\n\n")
last = paragraphs[-1].split(b"\n") if msg else []
trailer = re.compile(rb"^[A-Za-z0-9][A-Za-z0-9-]*: \S")
if len(paragraphs) > 1 and last and all(trailer.match(line) for line in last):
    commit.message = msg + b"\nUpstream: " + url + b"\n"
elif msg:
    commit.message = msg + b"\n\nUpstream: " + url + b"\n"
else:
    commit.message = b"Upstream: " + url + b"\n"
'

cd "$clone"
"$filter_repo" --force --quiet \
	--paths-from-file "$here/paths.txt" \
	--commit-callback "$callback"
