#!/bin/bash
# Set the APT_REPO_TOKEN secret on every source repo in packages.tsv.
#
# The token lets a source repo's release workflow start the update workflow
# here, so a new release lands without waiting for the daily cron.  README.md
# describes the token and why it is scoped the way it is.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Every repo in packages.tsv gets the token except these.  A secret is
# readable by anyone who can run a workflow in the repo holding it, so the
# token goes only in repos whose push access we control.  A skip here is a
# decision, and it says why; a skipped repo is still picked up by the cron.
declare -rA SKIP=(
  [PAARA-org/w6otx]="another org: push access there is not ours to control"
)

main() {
  # Read the token rather than take it as an argument: an argument lands in
  # shell history and is visible in `ps` for as long as the script runs.
  if [[ $# -ne 0 ]]; then
    cat >&2 <<EOT
Usage: $0
Reads the token from the terminal; do not pass it as an argument.
EOT
    exit 1
  fi

  local token
  read -rsp "Token for APT_REPO_TOKEN: " token
  echo
  if [[ -z "${token}" ]]; then
    echo "No token given." >&2
    exit 1
  fi

  # Setting a secret needs admin on the repo, so a call can fail.  Collect
  # the failures and report them at the end rather than stopping partway.
  local repo failed=()
  while IFS=$'\t' read -r repo _; do
    if [[ -v SKIP[${repo}] ]]; then
      echo "Skipping ${repo}: ${SKIP[${repo}]}"
      continue
    fi
    echo "Setting APT_REPO_TOKEN on ${repo}..."
    # Through stdin, not --body, to keep the token out of `ps`.
    if ! printf '%s' "${token}" | gh secret set APT_REPO_TOKEN --repo "${repo}"
    then
      failed+=("${repo}")
    fi
  done < <(packages)

  if [[ ${#failed[@]} -gt 0 ]]; then
    cat >&2 <<EOT

Failed to set APT_REPO_TOKEN on ${#failed[@]} repo(s):
$(printf '  %s\n' "${failed[@]}")

Setting a secret requires admin on the repository.  Until it is set, that
repo's trigger-apt-repo job fails on a tagged release and the APT repo picks
the release up on its daily cron instead.
EOT
    exit 1
  fi
  echo "Done."
}

main "$@"
