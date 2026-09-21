#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t REPOS < <(awk -F'\t' '!/^#/ && NF>0 {print $1}' "${SCRIPT_DIR}/packages.tsv")

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <token>" >&2
    exit 1
fi

TOKEN="$1"

# Every repo in packages.tsv, except the ones listed below: a repo we do
# not control needs deciding about, not silently dropping -- quietly
# filtering to charlieh0tel/ is how PAARA-org/w6otx went unnoticed
# without a token.  A skip here is a decision, and it says why.
#
# A secret is readable by anyone who can run a workflow in that repo, and
# this token can write to apt-repo, whose .debs install as root.  So it
# goes only in repos whose push access we control.  A skipped repo still
# gets its releases picked up by the daily cron.
declare -A SKIP=(
    [PAARA-org/w6otx]="another org: push access there is not ours to control"
)

# Setting a secret needs admin on the repo, so a call can still fail --
# collect the failures and report them at the end rather than aborting
# partway through and leaving the repos after it unset.
FAILED=()

for repo in "${REPOS[@]}"; do
    if [[ -v SKIP[$repo] ]]; then
        echo "Skipping $repo: ${SKIP[$repo]}"
        continue
    fi
    echo "Setting APT_REPO_TOKEN on $repo..."
    if ! gh secret set APT_REPO_TOKEN --repo "$repo" --body "$TOKEN"; then
        FAILED+=("$repo")
    fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo >&2
    echo "Failed to set APT_REPO_TOKEN on ${#FAILED[@]} repo(s):" >&2
    printf '  %s\n' "${FAILED[@]}" >&2
    echo >&2
    echo "Setting a secret requires admin on the repository.  Until it is" >&2
    echo "set, that repo's trigger-apt-repo job fails on a tagged release" >&2
    echo "and the APT repo picks the release up on its daily cron instead." >&2
    exit 1
fi

echo "Done."
