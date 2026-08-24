#!/usr/bin/env bash
set -euo pipefail

DOMAIN="aloestelam.ir"
EMAIL="${CERTBOT_EMAIL:-admin@aloestelam.ir}"
DEPLOY_DIR="/var/www/aloestelam/deploy"
NGINX_SITE_SRC="${DEPLOY_DIR}/aloestelam.ir.conf"
CHALLENGE_DIR="/var/www/certbot/.well-known/acme-challenge"
EXPECTED_IP="${EXPECTED_ORIGIN_IP:-65.109.221.32}"

log() { echo "[aloestelam-cert] $*"; }

cleanup_ephemeral() {
  log "Cleaning ephemeral cert timer/files..."
  systemctl disable --now aloestelam-cert.timer 2>/dev/null || true
  systemctl stop aloestelam-cert.service 2>/dev/null || true
  rm -f /etc/systemd/system/aloestelam-cert.timer
  rm -f /etc/systemd/system/aloestelam-cert.service
  rm -f /etc/systemd/system/timers.target.wants/aloestelam-cert.timer
  systemctl daemon-reload 2>/dev/null || true
  systemctl reset-failed aloestelam-cert.service aloestelam-cert.timer 2>/dev/null || true

  rm -f "${CHALLENGE_DIR}/aloestelam-ready"
  rm -f /var/www/aloestelam/.ssl-ready
  rm -f "${DEPLOY_DIR}/auto-issue-cert.sh"
  rm -f "${DEPLOY_DIR}/install-runtime.sh"
  rm -f /tmp/aloestelam-deploy-bundle.tgz
  rm -f /tmp/aloestelam-publish.tar.gz
  rm -f /tmp/aloestelam.ir.conf /tmp/aloestelam.service /tmp/bootstrap-server.sh /tmp/issue-cert.sh /tmp/remote-deploy.sh
  rm -rf /tmp/aloestelam-deploy /tmp/aloestelam-deploy-bundle

  log "Ephemeral cert artifacts removed."
}

apply_ssl_nginx() {
  if [[ -f "${NGINX_SITE_SRC}" ]]; then
    install -m 644 "${NGINX_SITE_SRC}" /etc/nginx/sites-available/aloestelam.ir
    nginx -t
    systemctl reload nginx
  fi
}

if [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
  log "Certificate already exists."
  apply_ssl_nginx
  cleanup_ephemeral
  exit 0
fi

mkdir -p "${CHALLENGE_DIR}"
TOKEN="ready-$(date +%s)-$RANDOM"
printf '%s' "${TOKEN}" > "${CHALLENGE_DIR}/aloestelam-ready"
chmod -R a+rX /var/www/certbot

dns_ready=0
if curl -fsS --connect-timeout 10 --max-time 20 \
  "http://${DOMAIN}/.well-known/acme-challenge/aloestelam-ready" \
  | grep -Fxq "${TOKEN}"; then
  dns_ready=1
  log "HTTP challenge reachable via ${DOMAIN}"
elif curl -fsS --connect-timeout 10 --max-time 20 \
  "http://www.${DOMAIN}/.well-known/acme-challenge/aloestelam-ready" \
  | grep -Fxq "${TOKEN}"; then
  dns_ready=1
  log "HTTP challenge reachable via www.${DOMAIN}"
else
  resolved="$(dig +short "${DOMAIN}" A | head -n1 || true)"
  if [[ "${resolved}" == "${EXPECTED_IP}" ]]; then
    if curl -fsS --connect-timeout 10 --max-time 20 \
      -H "Host: ${DOMAIN}" \
      "http://${EXPECTED_IP}/.well-known/acme-challenge/aloestelam-ready" \
      | grep -Fxq "${TOKEN}"; then
      dns_ready=1
      log "Origin IP reachable with Host ${DOMAIN} (resolved=${resolved})"
    fi
  else
    log "Not ready yet. resolved=${resolved:-none} expected_or_cf=${EXPECTED_IP}/cloudflare"
  fi
fi

if [[ "${dns_ready}" -ne 1 ]]; then
  log "DNS/Cloudflare not ready for ACME yet. Will retry later."
  exit 0
fi

log "Issuing Let's Encrypt certificate..."
certbot certonly --webroot -w /var/www/certbot \
  -d "${DOMAIN}" -d "www.${DOMAIN}" \
  --email "${EMAIL}" --agree-tos --non-interactive --keep-until-expiring

apply_ssl_nginx
cleanup_ephemeral
log "TLS enabled for ${DOMAIN}"
