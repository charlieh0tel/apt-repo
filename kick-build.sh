#!/bin/bash
# Kick the build: dispatch the update workflow and follow it to the end.
#
# The repository rebuilds on its own every morning, so this is for when a
# release has just gone out and waiting a day is not wanted.  It exits
# non-zero if the run fails, so it can sit at the end of a release recipe.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly WORKFLOW_URL="https://github.com/${REPO}/actions/workflows/${WORKFLOW}"

usage() {
  cat >&2 <<EOT
Usage: $0 [--no-watch]
Dispatches ${WORKFLOW} in ${REPO} and watches the run until it finishes.
  --no-watch   dispatch and return without waiting
EOT
}

#######################################
# Print the id of the newest dispatched run, or nothing if there is none.
#######################################
latest_run() {
  gh run list --repo "${REPO}" --workflow "${WORKFLOW}" \
    --event workflow_dispatch --limit 1 \
    --json databaseId --jq '.[0].databaseId // empty'
}

main() {
  local arg watch=1
  for arg in "$@"; do
    case "${arg}" in
      --no-watch) watch=0 ;;
      -h|--help) usage; exit 0 ;;
      *) usage; exit 1 ;;
    esac
  done

  # `gh workflow run` returns nothing to identify the run it started, so
  # remember the newest run beforehand and wait for a newer one to show up.
  local before run_id=""
  before="$(latest_run)"
  echo "Dispatching ${WORKFLOW} in ${REPO}..."
  gh workflow run "${WORKFLOW}" --repo "${REPO}"

  if (( ! watch )); then
    echo "Dispatched.  Follow it at ${WORKFLOW_URL}"
    exit 0
  fi

  # The run can take a few seconds to appear after the dispatch is accepted.
  for (( i = 0; i < 30; i++ )); do
    sleep 2
    run_id="$(latest_run)"
    [[ -n "${run_id}" && "${run_id}" != "${before}" ]] && break
    run_id=""
  done
  if [[ -z "${run_id}" ]]; then
    cat >&2 <<EOT
Dispatched, but the run has not appeared after a minute.
Check ${WORKFLOW_URL}
EOT
    exit 1
  fi

  echo "Run ${run_id}: https://github.com/${REPO}/actions/runs/${run_id}"
  exec gh run watch "${run_id}" --repo "${REPO}" --exit-status
}

main "$@"
