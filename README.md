# apt-repo

APT repository hosted on GitHub Pages. Packages are built from various repos and published here for easy installation via `apt`.

## Adding the repository to a host

Run the following on the target machine to trust the signing key, add the repo, and install a package:

```bash
# Import the signing key
curl -fsSL https://charlieh0tel.github.io/apt-repo/public.key | sudo gpg --dearmor -o /usr/share/keyrings/charlieh0tel.gpg

# Add the repository
echo "deb [signed-by=/usr/share/keyrings/charlieh0tel.gpg] https://charlieh0tel.github.io/apt-repo bookworm main" | sudo tee /etc/apt/sources.list.d/charlieh0tel.list

# Update and install
sudo apt-get update
sudo apt-get install rotaryclub   # or any other package
```

## Available packages

<!-- packages-start -->
| Package | Source | Description |
|---------|--------|-------------|
| **asl-dmr-bridge** | [charlieh0tel/asl-dmr-bridge](https://github.com/charlieh0tel/asl-dmr-bridge) | ASL DMR Bridge |
| **lantiq-exporter** | [charlieh0tel/lantiq-exporter](https://github.com/charlieh0tel/lantiq-exporter) | Prometheus exporter for a Lantiq/Falcon GPON ONT |
| **renogymon** | [charlieh0tel/renogymon](https://github.com/charlieh0tel/renogymon) | Renogy BMS monitoring tools |
| **rotaryclub** | [charlieh0tel/rotaryclub](https://github.com/charlieh0tel/rotaryclub) | Pseudo-Doppler radio direction finding |
| **smartclockmon** | [charlieh0tel/smartclockmon](https://github.com/charlieh0tel/smartclockmon) | HP / Symmetricom SmartClock GPS receiver monitoring |
| **usbrelay-rs** | [charlieh0tel/usbrelay-rs](https://github.com/charlieh0tel/usbrelay-rs) | USB relay utilities |
| **weather** | [charlieh0tel/weather-rs](https://github.com/charlieh0tel/weather-rs) | Weather with text-to-speech |
| **wg-netns** | [charlieh0tel/wg-netns](https://github.com/charlieh0tel/wg-netns) | WireGuard in network namespaces |
| **w6otx** | [PAARA-org/w6otx](https://github.com/PAARA-org/w6otx) | W6OTX repeater power control |
<!-- packages-end -->

## Maintaining this repository

### Triggering a rebuild

The repository rebuilds automatically every day at 06:00 UTC, so new package releases will appear within a day with no additional setup. A rebuild can also be triggered manually:

The workflow runs in two jobs. `build` fetches the latest release of every
repository in `packages.tsv`, assembles the repository with `reprepro` and
signs it; `publish` takes what `build` produced and pushes it to `gh-pages`.
They are separate so that the third-party action that publishes never runs in
a job where the signing key exists.

**Via the GitHub UI:** Go to [Actions → Update APT Repository](https://github.com/charlieh0tel/apt-repo/actions/workflows/update-repo.yml), click **Run workflow**, and confirm.

**Via the CLI:**
```bash
gh workflow run update-repo.yml --repo charlieh0tel/apt-repo
```

### Adding a source repo

To add a new source repository whose `.deb` releases will be included in this APT repo:

1. Add a line to `packages.tsv` (tab-separated: `owner/repo`, package name, description):

   ```
   owner/new-repo	package-name	Short description
   ```

2. Run `./update-packages.sh` to regenerate the packages table in this README.

3. Optionally, configure the source repo to trigger an immediate rebuild whenever it publishes a release, rather than waiting for the daily cron.

   Add this job to the workflow that publishes the release, naming whichever job builds the package in `needs:`:

   ```yaml
   trigger-apt-repo:
     needs: build-deb
     # Only for tags, when the workflow also runs on branches or PRs.
     if: startsWith(github.ref, 'refs/tags/v')
     runs-on: ubuntu-22.04
     steps:
       - name: Trigger APT repo rebuild
         uses: peter-evans/repository-dispatch@v4
         with:
           token: ${{ secrets.APT_REPO_TOKEN }}
           repository: charlieh0tel/apt-repo
           event-type: update-apt-repo
   ```

   `needs:` matters: without it the dispatch can fire for a release that failed to build, and the rebuild finds nothing to fetch.

   A job rather than a step, because a repo whose package is built by a reusable workflow has no step of its own to put this after. Where the release is published by a step in this same workflow, the same `Trigger APT repo rebuild` step can simply follow it.

   **Setup:**

   1. Create a fine-grained [Personal Access Token](https://github.com/settings/personal-access-tokens) restricted to the `charlieh0tel/apt-repo` repository, with `Actions: Read and write` and nothing else. (`Metadata: Read-only` is added for you and cannot be removed.) Not `Contents: Read and write`: that would let the token push a commit to `update-repo.yml`, the workflow that imports the GPG key.
   2. Add the token as a secret named `APT_REPO_TOKEN` in the source repository's settings (`Settings → Secrets and variables → Actions`).

   To apply the token to the source repos in `packages.tsv` at once, run
   `set-apt-repo-token.sh`. It takes no arguments and reads the token from the
   terminal, so the token stays out of your shell history and out of `ps`.

   The token can start workflows in this repository, and a secret is readable
   by anyone who can run a workflow in the repo holding it, so it goes only in
   repos whose push access we control.  A repo we do not control is listed in the
   script's `SKIP` table with the reason, rather than quietly left out.  Such a
   repo needs no dispatch job: the daily cron above fetches the latest release
   of every repo listed here, so its packages still land, with up to a day of
   lag.  To pick one up sooner, run the update workflow by hand:

   ```
   gh workflow run update-repo.yml -R charlieh0tel/apt-repo
   ```

## License

MIT
