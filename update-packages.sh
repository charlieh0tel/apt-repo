#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_TSV="${SCRIPT_DIR}/packages.tsv"
README="${SCRIPT_DIR}/README.md"

table="| Package | Source | Description |
|---------|--------|-------------|"

while IFS=$'\t' read -r repo package description; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    url="https://github.com/${repo}"
    table+=$'\n'"| **${package}** | [${repo}](${url}) | ${description} |"
done < "$PACKAGES_TSV"

awk -v table="$table" '
/<!-- packages-start -->/ { print; print table; skip=1; next }
/<!-- packages-end -->/ { skip=0 }
!skip { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

echo "Updated ${README}"
