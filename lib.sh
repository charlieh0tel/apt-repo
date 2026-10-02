#!/bin/bash
# Shared definitions for the apt-repo scripts.  Source it; do not run it.
#
# shellcheck disable=SC2034  # the constants are for the scripts sourcing this

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR
readonly PACKAGES_TSV="${REPO_DIR}/packages.tsv"

readonly OWNER="charlieh0tel"
readonly REPO="${OWNER}/apt-repo"
readonly WORKFLOW="update-repo.yml"
readonly SUITE="bookworm"
readonly PAGES_URL="https://${OWNER}.github.io/apt-repo"

#######################################
# Print the rows of packages.tsv, sorted, without comments or blank lines.
# Outputs:
#   One tab-separated row per line: repo, package, description.
#######################################
packages() {
  awk -F'\t' '!/^#/ && NF > 0' "${PACKAGES_TSV}" | sort -t $'\t' -k2,2
}
