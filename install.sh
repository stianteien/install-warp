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

echo "Configuring SSH..."

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

mkdir -p "$SSH_DIR"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "Creating SSH config file..."
    touch "$SSH_CONFIG"
fi

if ! grep -q "^Host pgx.babelspeak.no" "$SSH_CONFIG" 2>/dev/null; then
    echo "Adding pgx.babelspeak.no SSH configuration..."

    cat >> "$SSH_CONFIG" <<EOF

Host pgx.babelspeak.no
    ProxyCommand $(command -v cloudflared) access ssh --hostname %h
    User $(whoami)
EOF

else
    echo "SSH configuration already exists."
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
