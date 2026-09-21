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

# Every repo in packages.tsv, not just charlieh0tel/ ones: a repo in
# another org needs the token just as much, and filtering them out is how
# PAARA-org/w6otx went unnoticed without one.  Setting a secret needs
# admin on the repo, so those may fail -- collect the failures and report
# them at the end rather than aborting partway through.
FAILED=()

for repo in "${REPOS[@]}"; do
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
