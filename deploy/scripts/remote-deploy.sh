#!/usr/bin/env bash
set -euo pipefail

APP_NAME="aloestelam"
APP_ROOT="/var/www/${APP_NAME}"
RELEASES_DIR="${APP_ROOT}/releases"
CURRENT_LINK="${APP_ROOT}/current"
SERVICE_NAME="${APP_NAME}.service"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
RELEASE_DIR="${RELEASES_DIR}/${TIMESTAMP}"
PACKAGE_PATH="${1:-/tmp/aloestelam-publish.tar.gz}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

if [[ ! -f "${PACKAGE_PATH}" ]]; then
  echo "Package not found: ${PACKAGE_PATH}" >&2
  exit 1
fi

mkdir -p "${RELEASES_DIR}"
mkdir -p "${RELEASE_DIR}"

tar -xzf "${PACKAGE_PATH}" -C "${RELEASE_DIR}"
chown -R www-data:www-data "${RELEASE_DIR}"

ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"
systemctl restart "${SERVICE_NAME}"
systemctl is-active --quiet "${SERVICE_NAME}"

mapfile -t OLD_RELEASES < <(ls -1dt "${RELEASES_DIR}"/* 2>/dev/null | tail -n +$((KEEP_RELEASES + 1)) || true)
if ((${#OLD_RELEASES[@]} > 0)); then
  rm -rf "${OLD_RELEASES[@]}"
fi

echo "Deployed ${APP_NAME} release ${TIMESTAMP}"
