#!/usr/bin/env bash
set -euo pipefail

# Install/refresh nginx site and app service.
# Auto-cert timer is installed only while certificate is missing.

APP_ROOT="/var/www/aloestelam"
DEPLOY_DIR="${APP_ROOT}/deploy"
SRC_DIR="${1:-/tmp/aloestelam-deploy}"
CERT_PATH="/etc/letsencrypt/live/aloestelam.ir/fullchain.pem"

mkdir -p "${DEPLOY_DIR}" /var/www/certbot/.well-known/acme-challenge

install -m 644 "${SRC_DIR}/aloestelam.ir.conf" "${DEPLOY_DIR}/aloestelam.ir.conf"
install -m 644 "${SRC_DIR}/aloestelam.service" /etc/systemd/system/aloestelam.service

if [[ -f "${CERT_PATH}" ]]; then
  install -m 644 "${DEPLOY_DIR}/aloestelam.ir.conf" /etc/nginx/sites-available/aloestelam.ir
  ln -sfn /etc/nginx/sites-available/aloestelam.ir /etc/nginx/sites-enabled/aloestelam.ir
  nginx -t
  systemctl reload nginx
  systemctl daemon-reload
  systemctl enable aloestelam.service

  # Cert already present: remove leftover ephemeral auto-cert units/files.
  systemctl disable --now aloestelam-cert.timer 2>/dev/null || true
  systemctl stop aloestelam-cert.service 2>/dev/null || true
  rm -f /etc/systemd/system/aloestelam-cert.timer
  rm -f /etc/systemd/system/aloestelam-cert.service
  rm -f /etc/systemd/system/timers.target.wants/aloestelam-cert.timer
  rm -f "${DEPLOY_DIR}/auto-issue-cert.sh" "${DEPLOY_DIR}/install-runtime.sh"
  rm -f /var/www/aloestelam/.ssl-ready
  rm -f /var/www/certbot/.well-known/acme-challenge/aloestelam-ready
  systemctl daemon-reload 2>/dev/null || true
  echo "Aloestelam runtime refreshed (TLS already active; ephemeral cert files removed)"
  exit 0
fi

install -m 755 "${SRC_DIR}/auto-issue-cert.sh" "${DEPLOY_DIR}/auto-issue-cert.sh"
install -m 644 "${SRC_DIR}/aloestelam-cert.service" /etc/systemd/system/aloestelam-cert.service
install -m 644 "${SRC_DIR}/aloestelam-cert.timer" /etc/systemd/system/aloestelam-cert.timer

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

ln -sfn /etc/nginx/sites-available/aloestelam.ir /etc/nginx/sites-enabled/aloestelam.ir
nginx -t
systemctl reload nginx

systemctl daemon-reload
systemctl enable aloestelam.service
systemctl enable --now aloestelam-cert.timer
systemctl start aloestelam-cert.service || true

echo "Aloestelam nginx + auto-cert timer installed (will self-remove after TLS success)"
systemctl list-timers 'aloestelam-cert.timer' --no-pager || true
