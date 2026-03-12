#!/usr/bin/env bash
set -e

echo "Detecting environment..."

if grep -qi microsoft /proc/version; then
    IS_WSL=true
    echo "Running inside WSL"
else
    IS_WSL=false
    echo "Running on native Linux"
fi

CODENAME=$(lsb_release -cs)

echo "Installing cloudflared..."

sudo mkdir -p --mode=0755 /usr/share/keyrings

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
| sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $CODENAME main" \
| sudo tee /etc/apt/sources.list.d/cloudflared.list

sudo apt-get update
sudo apt-get install -y cloudflared

echo "Locating cloudflared..."
CLOUDFLARED_PATH=$(command -v cloudflared)

if [ -z "$CLOUDFLARED_PATH" ]; then
    echo "cloudflared not found!"
    exit 1
fi

echo "cloudflared located at: $CLOUDFLARED_PATH"

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG"

echo "Updating SSH config..."

if ! grep -q "^Host pgx.babelspeak.no" "$SSH_CONFIG"; then
cat <<EOF >> "$SSH_CONFIG"

Host pgx.babelspeak.no
    ProxyCommand $CLOUDFLARED_PATH access ssh --hostname %h
    User $(whoami)
EOF
    echo "SSH config added."
else
    echo "SSH config already exists."
fi

# Skip WARP on WSL because it cannot run there
if [ "$IS_WSL" = true ]; then
    echo "Skipping WARP install because it does not work in WSL."
    echo "Install WARP on Windows instead."
    exit 0
fi

echo "Installing Cloudflare WARP..."

curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
| sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $CODENAME main" \
| sudo tee /etc/apt/sources.list.d/cloudflare-client.list

sudo apt-get update
sudo apt-get install -y cloudflare-warp

echo "Registering WARP..."
sudo warp-cli registration new

echo "Connecting WARP..."
warp-cli connect

echo "Setup complete!"
