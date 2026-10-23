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
# Print the rows of packages.tsv, sorted by repo then package with repos
# outside ${OWNER} last, without comments or blank lines.
# Outputs:
#   One tab-separated row per line: repo, package, description.
#######################################
packages() {
  awk -F'\t' -v OFS='\t' -v owner="${OWNER}/" '
    !/^#/ && NF > 0 { print (index($1, owner) != 1), $0 }
  ' "${PACKAGES_TSV}" \
    | LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3 \
    | cut -f2-
}

#######################################
# Print the rows of packages.tsv for a table grouped by repo: the repo only
# on the first of its rows, empty on the rest.
# Outputs:
#   One tab-separated row per line: repo or empty, package, description.
#######################################
package_table() {
  packages | awk -F'\t' -v OFS='\t' '
    { print ($1 == prev ? "" : $1), $2, $3; prev = $1 }
  '
}

#######################################
# Print each source repo in packages.tsv once, though it may list several
# packages.
# Outputs:
#   One owner/repo per line.
#######################################
repos() {
  packages | cut -f1 | sort -u
}
