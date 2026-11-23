#!/bin/bash
# Check packages.tsv, conf/distributions and public.key for what the other
# scripts and the published install instructions rely on.  It needs gpg.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly DISTRIBUTIONS="${REPO_DIR}/conf/distributions"

#######################################
# Check every row of packages.tsv: three non-empty fields, a GitHub repo, a
# Debian package name listed once, and a description that is safe to paste
# into the HTML and Markdown tables.
# Outputs:
#   One line per problem, to stderr.
# Returns:
#   Non-zero if there is a problem.
#######################################
check_packages() {
  awk -F'\t' '
    function bad(msg) {
      printf "packages.tsv:%d: %s\n", NR, msg > "/dev/stderr"
      status = 1
    }
    /^#/ || /^$/ { next }
    NF != 3 { bad("want 3 tab-separated fields, got " NF); next }
    $1 !~ /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/ { bad("bad repo: " $1) }
    $2 !~ /^[a-z0-9][a-z0-9+.-]+$/ { bad("bad package name: " $2) }
    $2 in seen { bad("package also on line " seen[$2] ": " $2) }
    { seen[$2] = NR }
    $3 == "" || $3 ~ /^ | $|[|<>&\r]/ { bad("bad description: " $3) }
    END { exit status }
  ' "${PACKAGES_TSV}"
}

#######################################
# Print the value of a field of conf/distributions.
# Arguments:
#   Field name.
#######################################
field() {
  sed -n "s/^$1: *//p" "${DISTRIBUTIONS}"
}

#######################################
# Check conf/distributions: one distribution, named ${SUITE}, with the
# component and architectures the install instructions and index page name,
# signed with a key that public.key holds.
# Outputs:
#   One line per problem, to stderr.
# Returns:
#   Non-zero if there is a problem.
#######################################
check_distributions() {
  local arch status=0
  if [[ "$(field Codename)" != "${SUITE}" ]]; then
    echo "conf/distributions: Codename is not the one suite ${SUITE}" >&2
    status=1
  fi
  if [[ "$(field Components)" != "main" ]]; then
    echo "conf/distributions: Components is not main" >&2
    status=1
  fi
  for arch in amd64 arm64; do
    if [[ " $(field Architectures) " != *" ${arch} "* ]]; then
      echo "conf/distributions: Architectures lacks ${arch}" >&2
      status=1
    fi
  done
  if ! gpg --show-keys --with-colons "${REPO_DIR}/public.key" \
      | grep -q "^fpr:.*:$(field SignWith | grep -Ex '[0-9A-F]{40}'):$"; then
    echo "conf/distributions: SignWith is not a fingerprint in public.key" >&2
    status=1
  fi
  return "${status}"
}

main() {
  local status=0
  check_packages || status=1
  check_distributions || status=1
  (( status == 0 )) && echo "packages.tsv and conf/distributions are OK"
  exit "${status}"
}

main "$@"
