#!/usr/bin/env bash
# Backend EC2 setup (Ubuntu 22.04/24.04). Run as: bash setup-backend.sh "<MONGO_URI>"
set -euo pipefail
MONGO_URI="${1:?usage: setup-backend.sh <MONGO_URI>}"

sudo apt update && sudo apt install -y nginx git curl
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

cd ~
[ -d TravelMemory ] || git clone https://github.com/UnpredictablePrashant/TravelMemory
cd TravelMemory/backend

cat > .env <<EOF
MONGO_URI=${MONGO_URI}
PORT=3000
EOF
chmod 600 .env

npm install
pm2 start index.js --name travelmemory-backend
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u "$USER" --hp "$HOME"

# Nginx reverse proxy -> localhost:3000
sudo cp ~/nginx-backend.conf /etc/nginx/sites-available/travelmemory-backend
sudo ln -sf /etc/nginx/sites-available/travelmemory-backend /etc/nginx/sites-enabled/travelmemory-backend
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "Backend up. Test: curl http://localhost/hello"
