#!/usr/bin/env bash

set -e

echo "Removing cloudflared and Cloudflare WARP..."

# Try to delete registration, ignore if it doesn't exist
sudo warp-cli registration delete || true

# Remove packages
sudo apt remove --purge -y cloudflared cloudflare-warp

# Clean unused dependencies
sudo apt autoremove -y

echo "Removing Cloudflare repositories..."

sudo rm -f /etc/apt/sources.list.d/cloudflared.list
sudo rm -f /etc/apt/sources.list.d/cloudflare-client.list

echo "Removing Cloudflare GPG keys..."

sudo rm -f /usr/share/keyrings/cloudflare-main.gpg
sudo rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo "Updating apt..."

sudo apt update

echo "Cloudflare components removed successfully."
