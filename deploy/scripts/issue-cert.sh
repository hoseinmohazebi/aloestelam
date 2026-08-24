#!/usr/bin/env bash
set -euo pipefail

DOMAIN="aloestelam.ir"
EMAIL="${CERTBOT_EMAIL:-admin@aloestelam.ir}"
NGINX_SITE_SRC="${1:-/tmp/aloestelam.ir.conf}"

certbot certonly --webroot -w /var/www/certbot \
  -d "${DOMAIN}" -d "www.${DOMAIN}" \
  --email "${EMAIL}" --agree-tos --non-interactive --keep-until-expiring

install -m 644 "${NGINX_SITE_SRC}" /etc/nginx/sites-available/aloestelam.ir
nginx -t
systemctl reload nginx
echo "TLS enabled for ${DOMAIN}"
