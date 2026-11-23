#!/bin/bash
# Dry run of the build: build the site signed with a throwaway key, then
# check it.  Pull requests run this.  It publishes nothing and uses a scratch
# keyring, so it cannot touch the real signing key.
#
# It needs what build-site.sh and check-site.sh need.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

main() {
  if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [SITE_DIR]" >&2
    exit 1
  fi
  local site="${1:-site}"
  GNUPGHOME="$(mktemp -d)"
  export GNUPGHOME
  trap 'gpgconf --kill all; rm -rf "${GNUPGHOME}"' EXIT

  gpg --batch --passphrase '' \
    --quick-generate-key 'apt-repo dry run' ed25519 sign 1d
  APT_REPO_SIGN_WITH="$(gpg --list-keys --with-colons \
    | awk -F: '$1 == "fpr" { print $10; exit }')"
  export APT_REPO_SIGN_WITH

  "${REPO_DIR}/build-site.sh" "${site}"
  "${REPO_DIR}/check-site.sh" "${site}"
}

main "$@"
