#!/usr/bin/env bash
# Kick the build: dispatch the update-repo workflow and follow it to the end.
#
# The repository rebuilds on its own every morning, so this is for when a
# release has just gone out and waiting a day is not wanted.  It exits
# non-zero if the run fails, so it can sit at the end of a release recipe.
set -o errexit
set -o nounset
set -o pipefail

REPO="charlieh0tel/apt-repo"
WORKFLOW="update-repo.yml"
WATCH=1

usage() {
    echo "Usage: $0 [--no-watch]" >&2
    echo "Dispatches ${WORKFLOW} in ${REPO} and watches the run until it finishes." >&2
    echo "  --no-watch   dispatch and return without waiting" >&2
}

for arg in "$@"; do
    case "$arg" in
        --no-watch) WATCH=0 ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# `gh workflow run` returns nothing to identify the run it started, so
# remember the newest run beforehand and wait for a newer one to show up.
latest_run() {
    gh run list --repo "$REPO" --workflow "$WORKFLOW" --event workflow_dispatch \
        --limit 1 --json databaseId --jq '.[0].databaseId // empty'
}

before="$(latest_run)"

echo "Dispatching ${WORKFLOW} in ${REPO}..."
gh workflow run "$WORKFLOW" --repo "$REPO"

if [[ $WATCH -eq 0 ]]; then
    echo "Dispatched.  Follow it at https://github.com/${REPO}/actions/workflows/${WORKFLOW}"
    exit 0
fi

# The run can take a few seconds to appear after the dispatch is accepted.
run_id=""
for _ in $(seq 1 30); do
    sleep 2
    run_id="$(latest_run)"
    if [[ -n "$run_id" && "$run_id" != "$before" ]]; then
        break
    fi
    run_id=""
done

if [[ -z "$run_id" ]]; then
    echo "Dispatched, but the run has not appeared after a minute." >&2
    echo "Check https://github.com/${REPO}/actions/workflows/${WORKFLOW}" >&2
    exit 1
fi

echo "Run ${run_id}: https://github.com/${REPO}/actions/runs/${run_id}"
exec gh run watch "$run_id" --repo "$REPO" --exit-status
