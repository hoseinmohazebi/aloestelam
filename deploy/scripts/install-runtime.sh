#!/usr/bin/env bash
set -euo pipefail

# Install/refresh nginx site, deploy helpers, and auto-cert timer.
# Safe to run on every deploy.

APP_ROOT="/var/www/aloestelam"
DEPLOY_DIR="${APP_ROOT}/deploy"
SRC_DIR="${1:-/tmp/aloestelam-deploy}"

mkdir -p "${DEPLOY_DIR}" /var/www/certbot/.well-known/acme-challenge

install -m 644 "${SRC_DIR}/aloestelam.ir.conf" "${DEPLOY_DIR}/aloestelam.ir.conf"
install -m 755 "${SRC_DIR}/auto-issue-cert.sh" "${DEPLOY_DIR}/auto-issue-cert.sh"
install -m 644 "${SRC_DIR}/aloestelam.service" /etc/systemd/system/aloestelam.service
install -m 644 "${SRC_DIR}/aloestelam-cert.service" /etc/systemd/system/aloestelam-cert.service
install -m 644 "${SRC_DIR}/aloestelam-cert.timer" /etc/systemd/system/aloestelam-cert.timer

# Keep/refresh HTTP reverse-proxy until TLS cert exists.
if [[ ! -f /etc/letsencrypt/live/aloestelam.ir/fullchain.pem ]]; then
  cat > /etc/nginx/sites-available/aloestelam.ir <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name aloestelam.ir www.aloestelam.ir;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass         http://127.0.0.1:5090;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
else
  install -m 644 "${DEPLOY_DIR}/aloestelam.ir.conf" /etc/nginx/sites-available/aloestelam.ir
fi

ln -sfn /etc/nginx/sites-available/aloestelam.ir /etc/nginx/sites-enabled/aloestelam.ir
nginx -t
systemctl reload nginx

systemctl daemon-reload
systemctl enable aloestelam.service
systemctl enable --now aloestelam-cert.timer

# Try immediately (no wait for next timer tick).
systemctl start aloestelam-cert.service || true

echo "Aloestelam nginx + auto-cert timer installed"
systemctl list-timers 'aloestelam-cert.timer' --no-pager || true
