#!/usr/bin/env bash

set -e

echo "Installing cloudflared..."

# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | \
    sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add repo
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main" | \
    sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install cloudflared
sudo apt-get update
sudo apt-get install -y cloudflared

echo "Locating cloudflared..."
CLOUDFLARED_PATH=$(which cloudflared)

if [ -z "$CLOUDFLARED_PATH" ]; then
    echo "cloudflared not found!"
    exit 1
fi

echo "cloudflared located at: $CLOUDFLARED_PATH"

SSH_CONFIG="$HOME/.ssh/config"
WSL_USER=$(whoami)

mkdir -p ~/.ssh
touch "$SSH_CONFIG"

echo "Updating SSH config..."

if ! grep -q "Host pgx.babelspeak.no" "$SSH_CONFIG"; then
cat <<EOF >> "$SSH_CONFIG"

Host pgx.babelspeak.no
    ProxyCommand $CLOUDFLARED_PATH access ssh --hostname %h
    User $WSL_USER
EOF
fi

echo "Installing Cloudflare WARP..."

# Add warp gpg key
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | \
    sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# Add repo
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# Install warp
sudo apt-get update
sudo apt-get install -y cloudflare-warp

echo "Registering WARP..."
printf 'y\n' | sudo warp-cli registration new

echo "Enabling WARP..."
sudo warp-cli connect

echo "Setup complete!"
