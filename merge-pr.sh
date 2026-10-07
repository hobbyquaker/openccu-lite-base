#!/bin/bash
# merge-pr.sh: open a pull request "Merge <tag> into lite" for every upstream release tag that
# `lite` does not contain yet. Run in a full clone of this repository (all branches and tags) with
# `gh` authenticated (GH_TOKEN). Never pushes to `lite`: the head of each pull request is a branch
# `merge/<tag>` at the tag, and the maintainer merges.
#
# A tag gets its pull request once. When one exists for `merge/<tag>`, open or closed, the tag is
# skipped; delete the branch `merge/<tag>` to have it opened again.
#
# DRY_RUN=1 prints what it would do and changes nothing.
set -euo pipefail

remote=${REMOTE:-origin}
lite=refs/remotes/$remote/lite
dry=${DRY_RUN:-0}

git rev-parse -q --verify "$lite" >/dev/null || { echo "::error::no branch lite on $remote"; exit 1; }

# upstream's release tags look like 3.89.11; ours are 3.89.11-lite.N
mapfile -t tags < <(git tag --list | grep -E '^[0-9]+(\.[0-9]+)+$' | sort -V)

for tag in "${tags[@]}"; do
	if git merge-base --is-ancestor "refs/tags/$tag" "$lite"; then
		continue  # merged already, or older than lite's base
	fi
	branch=merge/$tag
	existing=$(gh pr list --repo "$GITHUB_REPOSITORY" --head "$branch" --state all \
		--json number,state --jq '.[] | "#\(.number) \(.state)"' | head -n 1)
	if [ -n "$existing" ]; then
		echo "$tag: pull request $existing exists, skipped"
		continue
	fi

	count=$(git rev-list --count "$lite..refs/tags/$tag")
	body=$(mktemp)
	{
		echo "OpenCCU-Base's release \`$tag\`, filtered: $count commit(s) that \`lite\` does not have yet."
		echo
		echo "Merge with a merge commit. A commit openccu-lite does not want is reverted on \`lite\` right after"
		echo "the merge, with the reason in the revert's message. Then tag \`lite\` as \`$tag-lite.1\` and pin that"
		echo "tag in the fork's \`openccu-base.mk\`."
		echo
		echo "| Commit | Upstream |"
		echo "| --- | --- |"
		git log --reverse --format='%H%x09%s%x09%(trailers:key=Upstream,valueonly,separator=)' \
			"$lite..refs/tags/$tag" |
			while IFS=$'\t' read -r hash subject upstream; do
				subject=${subject//|/\\|}
				echo "| ${hash:0:12} $subject | ${upstream:-?} |"
			done
	} > "$body"
	# GitHub limits a pull request body to 65536 characters
	if [ "$(wc -c < "$body")" -gt 60000 ]; then
		head -c 60000 "$body" > "$body.cut"
		printf '\n\n(list cut: %s commits in all, see `git log lite..%s`)\n' "$count" "$tag" >> "$body.cut"
		mv "$body.cut" "$body"
	fi

	if [ "$dry" = 1 ]; then
		echo "$tag: would push $branch at $(git rev-parse --short "refs/tags/$tag^{commit}") and open \"Merge $tag into lite\""
		cat "$body"
	else
		git push "$remote" "$(git rev-parse "refs/tags/$tag^{commit}"):refs/heads/$branch"
		gh pr create --repo "$GITHUB_REPOSITORY" --base lite --head "$branch" \
			--title "Merge $tag into lite" --body-file "$body"
		echo "$tag: pull request opened"
	fi
	rm -f "$body"
done
