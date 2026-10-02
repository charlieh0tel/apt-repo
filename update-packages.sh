#!/bin/bash
# Regenerate the package table in README.md from packages.tsv.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly README="${REPO_DIR}/README.md"

main() {
  local table
  table="$(packages | awk -F'\t' '
    BEGIN {
      print "| Package | Source | Description |"
      print "|---------|--------|-------------|"
    }
    { printf "| **%s** | [%s](https://github.com/%s) | %s |\n", $2, $1, $1, $3 }
  ')"
  awk -v table="${table}" '
    /<!-- packages-start -->/ { print; print table; skip = 1; next }
    /<!-- packages-end -->/ { skip = 0 }
    !skip { print }
  ' "${README}" > "${README}.tmp" && mv "${README}.tmp" "${README}"
  echo "Updated ${README}"
}

main "$@"
