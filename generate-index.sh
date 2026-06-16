#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_TSV="${SCRIPT_DIR}/packages.tsv"
OUT="${1:-${SCRIPT_DIR}/site/index.html}"

rows=$(awk -F'\t' '!/^#/ && NF>0 {
  printf "<tr><td><code>%s</code></td><td><a href=\"https://github.com/%s\">%s</a></td><td>%s</td></tr>\n", $2, $1, $1, $3
}' "$PACKAGES_TSV" | sort)

cat > "$OUT" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>charlieh0tel APT repository</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body { font-family: system-ui, sans-serif; max-width: 48rem; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
  code, pre { font-family: ui-monospace, monospace; }
  pre { background: #f4f4f4; padding: 1rem; overflow-x: auto; }
  table { border-collapse: collapse; width: 100%; }
  th, td { text-align: left; padding: 0.4rem 0.6rem; border-bottom: 1px solid #ddd; }
</style>
</head>
<body>
<h1>charlieh0tel APT repository</h1>
<p>APT repository hosted on GitHub Pages. See the
<a href="https://github.com/charlieh0tel/apt-repo">source repo</a> for details.</p>
<h2>Adding the repository</h2>
<pre>curl -fsSL https://charlieh0tel.github.io/apt-repo/public.key | sudo gpg --dearmor -o /usr/share/keyrings/charlieh0tel.gpg
echo "deb [signed-by=/usr/share/keyrings/charlieh0tel.gpg] https://charlieh0tel.github.io/apt-repo bookworm main" | sudo tee /etc/apt/sources.list.d/charlieh0tel.list
sudo apt-get update</pre>
<h2>Available packages</h2>
<table>
<thead><tr><th>Package</th><th>Source</th><th>Description</th></tr></thead>
<tbody>
${rows}
</tbody>
</table>
<p><a href="public.key">GPG public key</a> &middot;
<a href="dists/bookworm/main/binary-amd64/Packages">amd64 Packages</a> &middot;
<a href="dists/bookworm/main/binary-arm64/Packages">arm64 Packages</a></p>
</body>
</html>
HTML

echo "Wrote ${OUT}"
