#!/bin/bash
# Regenerate the package table in README.md from packages.tsv.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly README="${REPO_DIR}/README.md"

main() {
  local table
  table="$(package_table | awk -F'\t' '
    BEGIN {
      print "| Source | Package | Description |"
      print "|--------|---------|-------------|"
    }
    {
      src = $1 == "" ? "" : sprintf("[%s](https://github.com/%s)", $1, $1)
      printf "| %s | **%s** | %s |\n", src, $2, $3
    }
  ')"
  awk -v table="${table}" '
    /<!-- packages-start -->/ { print; print table; skip = 1; next }
    /<!-- packages-end -->/ { skip = 0 }
    !skip { print }
  ' "${README}" > "${README}.tmp" && mv "${README}.tmp" "${README}"
  echo "Updated ${README}"
}

main "$@"
