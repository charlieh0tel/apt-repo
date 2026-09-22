#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t REPOS < <(awk -F'\t' '!/^#/ && NF>0 {print $1}' "${SCRIPT_DIR}/packages.tsv")

# Read rather than take an argument. A token on the command line is in the
# shell history of whoever ran it and in `ps` output while it runs, which is
# a poor resting place for a credential that can start workflows in the
# repository that signs every package.
if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    echo "Reads the token from the terminal; do not pass it as an argument." >&2
    exit 1
fi

read -rsp "Token for APT_REPO_TOKEN: " TOKEN
echo
if [[ -z "$TOKEN" ]]; then
    echo "No token given." >&2
    exit 1
fi

# Every repo in packages.tsv, except the ones listed below: a repo we do
# not control needs deciding about, not silently dropping -- quietly
# filtering to charlieh0tel/ is how PAARA-org/w6otx went unnoticed
# without a token.  A skip here is a decision, and it says why.
#
# A secret is readable by anyone who can run a workflow in that repo, and
# this token can start workflows in apt-repo, whose .debs install as root.
# So it goes only in repos whose push access we control.  The token wants
# Actions: write on apt-repo and nothing else -- not Contents: write, which
# would let it rewrite the workflow that holds the signing key.  A skipped repo still
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
    # Through stdin, not --body: an argument is visible in `ps` for as long
    # as the call takes.
    if ! printf '%s' "$TOKEN" | gh secret set APT_REPO_TOKEN --repo "$repo"; then
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
