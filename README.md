# apt-repo

APT repository hosted on GitHub Pages. Packages are built from various repos and published here for easy installation via `apt`.

## Setup

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

- **renogy-rs** -- Renogy BMS monitoring tools
- **rotaryclub** -- Pseudo-Doppler radio direction finding
- **usbrelay-rs** -- USB relay utilities
- **weather** -- Weather with text-to-speech
- **wg-netns** -- WireGuard in network namespaces

## Updating the repository

The repository is rebuilt when:
- Manually triggered via `workflow_dispatch`
- A repo sends a `repository_dispatch` event with type `update-apt-repo`

## License

MIT
