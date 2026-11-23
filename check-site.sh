#!/bin/bash
# Check a site built by build-site.sh: the signatures verify against the
# public.key it publishes, and apt can update from it with that key alone.
#
# It needs apt-get, gpg and gpgv, and runs unprivileged.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

#######################################
# Run apt-get update against the site and nothing else, with all of apt's
# state in a scratch directory.
# Arguments:
#   Site directory, absolute.
#   Scratch directory holding keyring.gpg.
#######################################
apt_update() {
  local archs
  archs="$(sed -n 's/^Architectures: *//p' "${REPO_DIR}/conf/distributions")"
  echo "deb [arch=${archs// /,} signed-by=$2/keyring.gpg]" \
    "file://$1 ${SUITE} main" > "$2/sources.list"
  mkdir -p "$2/state" "$2/cache"
  # apt-get update exits 0 on a failed fetch or signature without Error-Mode.
  apt-get update \
    -o APT::Update::Error-Mode=any \
    -o Dir::Etc::sourcelist="$2/sources.list" \
    -o Dir::Etc::sourceparts=- \
    -o Dir::State="$2/state" \
    -o Dir::Cache="$2/cache"
}

#######################################
# Check that each architecture has packages, and that every package in
# packages.tsv is in at least one of them.
# Arguments:
#   Site directory.
#######################################
check_packages() {
  local index missing
  local -x LC_ALL=C  # sort and comm must agree on the order
  for index in "$1/dists/${SUITE}"/main/binary-*/Packages; do
    if ! grep -q '^Package: ' "${index}"; then
      echo "${index} has no packages" >&2
      exit 1
    fi
  done
  missing="$(comm -23 <(packages | cut -f2 | sort) \
    <(sed -n 's/^Package: //p' "$1/dists/${SUITE}"/main/binary-*/Packages \
      | sort -u) | paste -sd' ')"
  if [[ -n "${missing}" ]]; then
    echo "In packages.tsv but in no index: ${missing}" >&2
    exit 1
  fi
}

main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 SITE_DIR" >&2
    exit 1
  fi
  local site dist
  site="$(cd "$1" && pwd)"
  dist="${site}/dists/${SUITE}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT

  [[ -s "${site}/index.html" ]]
  gpg --dearmor < "${site}/public.key" > "${tmp}/keyring.gpg"
  gpgv --keyring "${tmp}/keyring.gpg" "${dist}/InRelease"
  gpgv --keyring "${tmp}/keyring.gpg" "${dist}/Release.gpg" "${dist}/Release"
  apt_update "${site}" "${tmp}"
  check_packages "${site}"
  echo "Checked ${site}"
}

main "$@"
