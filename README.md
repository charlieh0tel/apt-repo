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

| Package | Source | Description |
|---------|--------|-------------|
| **asl-dmr-bridge** | [charlieh0tel/asl-dmr-bridge](https://github.com/charlieh0tel/asl-dmr-bridge) | ASL DMR Bridge |
| **renogy-rs** | [charlieh0tel/renogy-rs](https://github.com/charlieh0tel/renogy-rs) | Renogy BMS monitoring tools |
| **rotaryclub** | [charlieh0tel/rotaryclub](https://github.com/charlieh0tel/rotaryclub) | Pseudo-Doppler radio direction finding |
| **usbrelay-rs** | [charlieh0tel/usbrelay-rs](https://github.com/charlieh0tel/usbrelay-rs) | USB relay utilities |
| **weather** | [charlieh0tel/weather-rs](https://github.com/charlieh0tel/weather-rs) | Weather with text-to-speech |
| **wg-netns** | [charlieh0tel/wg-netns](https://github.com/charlieh0tel/wg-netns) | WireGuard in network namespaces |
| **w6otx** | [PAARA-org/w6otx](https://github.com/PAARA-org/w6otx) | W6OTX repeater power control |

## Updating the repository

The repository is rebuilt when:
- Manually triggered via `workflow_dispatch`
- Automatically every day at 06:00 UTC via a scheduled cron job
- A source repo sends a `repository_dispatch` event with type `update-apt-repo`

### Manual update

**Via the GitHub UI:** Go to [Actions → Update APT Repository](https://github.com/charlieh0tel/apt-repo/actions/workflows/update-repo.yml), click **Run workflow**, and confirm.

**Via the CLI:**
```bash
gh workflow run update-repo.yml --repo charlieh0tel/apt-repo
```

### Configuring a repo to trigger an APT repo rebuild

After publishing a new release, a source repo can notify this APT repo to rebuild immediately by sending a `repository_dispatch` event. Add the following step to the source repo's release workflow:

```yaml
- name: Trigger APT repo rebuild
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.APT_REPO_TOKEN }}
    repository: charlieh0tel/apt-repo
    event-type: update-apt-repo
```

**Setup:**

1. Create a [Personal Access Token](https://github.com/settings/tokens) (classic or fine-grained) with `repo` scope on the `charlieh0tel/apt-repo` repository.
2. Add the token as a secret named `APT_REPO_TOKEN` in the source repository's settings (`Settings → Secrets and variables → Actions`).
3. Add the step above after the step that publishes the release.

## License

MIT
