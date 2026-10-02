#!/bin/bash
# Build the APT repository: fetch the latest .deb release of every repo in
# packages.tsv, add them with reprepro, and write the site index.
#
# CI runs this.  It needs gh, reprepro and the signing key in the keyring.
set -o errexit -o nounset -o pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

#######################################
# Download the latest release's .debs of every listed repo.
# Arguments:
#   Directory to download into.
#######################################
fetch_debs() {
  local repo
  while IFS=$'\t' read -r repo _; do
    echo "Fetching latest release from ${repo}..."
    gh release download --repo "${repo}" --pattern '*.deb' --dir "$1" \
      2>/dev/null || echo "  No release found for ${repo}"
  done < <(packages)
}

#######################################
# Add every .deb to the repository and sign it.
# Arguments:
#   Site directory to build into.
#   Directory holding the .debs.
#######################################
build_repo() {
  local deb
  mkdir -p "$1/conf"
  cp "${REPO_DIR}/conf/distributions" "$1/conf/"
  for deb in "$2"/*.deb; do
    [[ -f "${deb}" ]] || continue
    echo "Adding ${deb}..."
    reprepro -V --basedir "$1" includedeb "${SUITE}" "${deb}" 2>&1 \
      || echo "  Skipped ${deb}"
  done
  cp "${REPO_DIR}/public.key" "$1/"
  rm -rf "$1/conf" "$1/db"
}

#######################################
# Write the landing page with the package table.
# Arguments:
#   Path of the HTML file to write.
#######################################
write_index() {
  local rows
  rows="$(packages | awk -F'\t' '{
    printf "<tr><td><code>%s</code></td>", $2
    printf "<td><a href=\"https://github.com/%s\">%s</a></td>", $1, $1
    printf "<td>%s</td></tr>\n", $3
  }')"
  cat > "$1" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${OWNER} APT repository</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body { font-family: system-ui, sans-serif; max-width: 48rem;
         margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
  code, pre { font-family: ui-monospace, monospace; }
  pre { background: #f4f4f4; padding: 1rem; overflow-x: auto; }
  table { border-collapse: collapse; width: 100%; }
  th, td { text-align: left; padding: 0.4rem 0.6rem;
           border-bottom: 1px solid #ddd; }
</style>
</head>
<body>
<h1>${OWNER} APT repository</h1>
<p>APT repository hosted on GitHub Pages. See the
<a href="https://github.com/${REPO}">source repo</a> for details.</p>
<h2>Adding the repository</h2>
<pre>curl -fsSL ${PAGES_URL}/public.key \\
  | sudo gpg --dearmor -o /usr/share/keyrings/${OWNER}.gpg
echo "deb [signed-by=/usr/share/keyrings/${OWNER}.gpg]" \\
  "${PAGES_URL} ${SUITE} main" \\
  | sudo tee /etc/apt/sources.list.d/${OWNER}.list
sudo apt-get update</pre>
<h2>Available packages</h2>
<table>
<thead><tr><th>Package</th><th>Source</th><th>Description</th></tr></thead>
<tbody>
${rows}
</tbody>
</table>
<p><a href="public.key">GPG public key</a> &middot;
<a href="dists/${SUITE}/main/binary-amd64/Packages">amd64 Packages</a> &middot;
<a href="dists/${SUITE}/main/binary-arm64/Packages">arm64 Packages</a></p>
</body>
</html>
HTML
}

main() {
  if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [SITE_DIR]" >&2
    exit 1
  fi
  local site="${1:-site}" debs
  debs="$(mktemp -d)"
  # Expanded now: the trap runs after main's locals are gone.
  trap "rm -rf '${debs}'" EXIT

  fetch_debs "${debs}"
  echo "Downloaded debs:"
  ls -l "${debs}"
  build_repo "${site}" "${debs}"
  write_index "${site}/index.html"
  echo "Built ${site}"
}

main "$@"
