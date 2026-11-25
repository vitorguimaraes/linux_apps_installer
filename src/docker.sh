#!/bin/bash
set -e

printf "\nInstalling Docker...\n"

sudo apt install ca-certificates curl gnupg -y

# Download and convert the key in a temporary directory first, so a failed download
# never overwrites a keyring that is already installed
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL -o "$tmp_dir/docker.asc" https://download.docker.com/linux/ubuntu/gpg
gpg --dearmor -o "$tmp_dir/docker.gpg" "$tmp_dir/docker.asc"
sudo install -m 644 "$tmp_dir/docker.gpg" /etc/apt/keyrings/docker.gpg

# UBUNTU_CODENAME is set on Ubuntu derivatives (Mint, Pop!_OS), where VERSION_CODENAME is not an Ubuntu one
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Custom `docker ps` format (kept if the user already has a config.json)
mkdir -p "$HOME/.docker"
if [[ ! -f "$HOME/.docker/config.json" ]]; then
  cat > "$HOME/.docker/config.json" <<'EOF'
{
"psFormat": "\\nName: \\t\\t{{.Names}}\\tCommand: {{.Command}}\\nNetworks: \\t{{.Networks}}\\nRunningFor: \\t{{.RunningFor}}\\nPorts: \\t\\t{{.Ports}}"
}
EOF
fi

# Run docker without sudo (takes effect on the next login)
sudo usermod -aG docker "$USER"

# Last on purpose: needs the network, and the setup above must not depend on it
sudo docker run --rm hello-world

if dpkg -s docker-ce 2>/dev/null | grep -q "Status: install ok installed"; then
  docker --version
  printf "Docker installed!\n"
else
  printf "Docker not installed!\n"
  exit 1
fi

if docker compose version > /dev/null 2>&1; then
  docker compose version
  printf "Docker Compose installed!\n"
else
  printf "Docker Compose not installed!\n"
  exit 1
fi

printf "\nLog out and back in (or reboot) to use docker without sudo.\n"
printf "\n*******************************************************************\n"
