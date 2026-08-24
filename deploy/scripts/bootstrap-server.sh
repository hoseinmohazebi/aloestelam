#!/usr/bin/env bash
set -euo pipefail

DOMAIN="aloestelam.ir"
APP_ROOT="/var/www/aloestelam"
NGINX_SITE_SRC="/tmp/aloestelam.ir.conf"
SERVICE_SRC="/tmp/aloestelam.service"
EMAIL="${CERTBOT_EMAIL:-admin@aloestelam.ir}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y nginx certbot python3-certbot-nginx curl

if ! command -v dotnet >/dev/null 2>&1; then
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  bash /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet
  ln -sfn /usr/share/dotnet/dotnet /usr/bin/dotnet
fi

mkdir -p "${APP_ROOT}/releases" /var/www/certbot
chown -R www-data:www-data "${APP_ROOT}"

install -m 644 "${SERVICE_SRC}" /etc/systemd/system/aloestelam.service
systemctl daemon-reload
systemctl enable aloestelam.service

# Bootstrap HTTP-only nginx so certbot can issue the first certificate.
cat > /etc/nginx/sites-available/aloestelam.ir <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name aloestelam.ir www.aloestelam.ir;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass         http://127.0.0.1:5080;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sfn /etc/nginx/sites-available/aloestelam.ir /etc/nginx/sites-enabled/aloestelam.ir
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

if [[ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
  if certbot certonly --webroot -w /var/www/certbot \
    -d "${DOMAIN}" -d "www.${DOMAIN}" \
    --email "${EMAIL}" --agree-tos --non-interactive --keep-until-expiring; then
    install -m 644 "${NGINX_SITE_SRC}" /etc/nginx/sites-available/aloestelam.ir
    nginx -t
    systemctl reload nginx
    echo "TLS enabled for ${DOMAIN}"
  else
    echo "Certbot skipped/failed. Keeping HTTP reverse-proxy until DNS for ${DOMAIN} points to this server."
  fi
else
  install -m 644 "${NGINX_SITE_SRC}" /etc/nginx/sites-available/aloestelam.ir
  nginx -t
  systemctl reload nginx
fi

echo "Server bootstrap completed for ${DOMAIN}"
