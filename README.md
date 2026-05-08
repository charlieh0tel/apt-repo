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
sudo apt-get install renogy-rs   # or any other package
```

## Available packages

<!-- packages-start -->
| Package | Source | Description |
|---------|--------|-------------|
| **asl-dmr-bridge** | [charlieh0tel/asl-dmr-bridge](https://github.com/charlieh0tel/asl-dmr-bridge) | ASL DMR Bridge |
| **renogy-rs** | [charlieh0tel/renogy-rs](https://github.com/charlieh0tel/renogy-rs) | Renogy BMS monitoring tools |
| **rotaryclub** | [charlieh0tel/rotaryclub](https://github.com/charlieh0tel/rotaryclub) | Pseudo-Doppler radio direction finding |
| **usbrelay-rs** | [charlieh0tel/usbrelay-rs](https://github.com/charlieh0tel/usbrelay-rs) | USB relay utilities |
| **weather** | [charlieh0tel/weather-rs](https://github.com/charlieh0tel/weather-rs) | Weather with text-to-speech |
| **wg-netns** | [charlieh0tel/wg-netns](https://github.com/charlieh0tel/wg-netns) | WireGuard in network namespaces |
| **w6otx** | [PAARA-org/w6otx](https://github.com/PAARA-org/w6otx) | W6OTX repeater power control |
<!-- packages-end -->

## Maintaining this repository

### Triggering a rebuild

The repository rebuilds automatically every day at 06:00 UTC, so new package releases will appear within a day with no additional setup. A rebuild can also be triggered manually:

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

3. Optionally, configure the source repo to trigger an immediate rebuild whenever it publishes a release, rather than waiting for the daily cron. Add this step to the source repo's release workflow:

   ```yaml
   - name: Trigger APT repo rebuild
     uses: peter-evans/repository-dispatch@v3
     with:
       token: ${{ secrets.APT_REPO_TOKEN }}
       repository: charlieh0tel/apt-repo
       event-type: update-apt-repo
   ```

   **Setup:**

   1. Create a fine-grained [Personal Access Token](https://github.com/settings/tokens) with `Contents: Read and write` permission on the `charlieh0tel/apt-repo` repository.
   2. Add the token as a secret named `APT_REPO_TOKEN` in the source repository's settings (`Settings → Secrets and variables → Actions`).
   3. Add the step above after the step that publishes the release.

   To apply the token to all `charlieh0tel/` source repos at once, use `set-apt-repo-token.sh`.

## License

MIT
