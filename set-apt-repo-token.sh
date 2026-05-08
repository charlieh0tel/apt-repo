#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t REPOS < <(awk -F'\t' '!/^#/ && NF>0 {print $1}' "${SCRIPT_DIR}/packages.tsv" | grep '^charlieh0tel/')

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <token>" >&2
    exit 1
fi

TOKEN="$1"

for repo in "${REPOS[@]}"; do
    echo "Setting APT_REPO_TOKEN on $repo..."
    gh secret set APT_REPO_TOKEN --repo "$repo" --body "$TOKEN"
done

echo "Done."
