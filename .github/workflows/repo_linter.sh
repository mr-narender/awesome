#!/bin/bash
set -eo pipefail

# A sync PR can add multiple repositories, not just one list submission.
REPOS_TO_LINT=$(
	git diff origin/main -- readme.md |
	# Look for changes (indicated by lines starting with +).
	(grep ^+ || true) |
	# Get the line that includes the readme.
	(grep -Eo 'https.*#readme' || true) |
	# Get just the URL.
	sed 's/#readme$//' |
	sort -u)

if [ -z "$REPOS_TO_LINT" ]; then
	echo "No new link found in the format:  https://....#readme"
	exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
INDEX=0
while IFS= read -r REPO_TO_LINT; do
	[ -n "$REPO_TO_LINT" ] || continue
	if ! [[ "$REPO_TO_LINT" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/?$ ]]; then
		echo "Invalid GitHub repository URL: $REPO_TO_LINT" >&2
		exit 1
	fi
	INDEX=$((INDEX + 1))
	REPO_DIR="$WORK_DIR/$INDEX"
	echo "Cloning $REPO_TO_LINT"
	git clone --depth=1 -- "$REPO_TO_LINT" "$REPO_DIR"
	(cd "$REPO_DIR" && npx --yes awesome-lint)
done <<< "$REPOS_TO_LINT"
