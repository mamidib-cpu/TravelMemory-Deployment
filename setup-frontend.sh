#!/usr/bin/env bash
# Frontend EC2 setup. Run as: bash setup-frontend.sh "https://api.yourdomain.com"
set -euo pipefail
BACKEND_URL="${1:?usage: setup-frontend.sh <backend base URL, no trailing slash>}"

sudo apt update && sudo apt install -y nginx git curl
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

cd ~
[ -d TravelMemory ] || git clone https://github.com/UnpredictablePrashant/TravelMemory
cd TravelMemory/frontend

# Point the frontend at the backend (check which form your copy of url.js uses)
cat src/url.js
echo "export const baseUrl = \"${BACKEND_URL}\";" > src/url.js

npm install
npm run build

sudo mkdir -p /var/www/travelmemory
sudo rm -rf /var/www/travelmemory/*
sudo cp -r build/* /var/www/travelmemory/

sudo cp ~/nginx-frontend.conf /etc/nginx/sites-available/travelmemory-frontend
sudo ln -sf /etc/nginx/sites-available/travelmemory-frontend /etc/nginx/sites-enabled/travelmemory-frontend
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "Frontend up. Test: curl -I http://localhost/"
