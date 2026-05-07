#!/usr/bin/env bash
set -euo pipefail

REPOS=(
    charlieh0tel/asl-dmr-bridge
    charlieh0tel/renogy-rs
    charlieh0tel/rotaryclub
    charlieh0tel/usbrelay-rs
    charlieh0tel/weather-rs
    charlieh0tel/wg-netns
    PAARA-org/w6otx
)

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
