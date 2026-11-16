#!/usr/bin/env bash
# Encrypted backup. Supply secrets via protected environment variables.
set -Eeuo pipefail
: "${BACKUP_PASSPHRASE:?Set BACKUP_PASSPHRASE}"; : "${DB_NAME:?Set DB_NAME}"; : "${DB_USER:?Set DB_USER}"; : "${DB_PASSWORD:?Set DB_PASSWORD}"
WP_ROOT="${WP_ROOT:-/var/www/html}"; BACKUP_DIR="${BACKUP_DIR:-/var/backups/cms}"
[[ -d "$WP_ROOT" ]] || { echo "WP_ROOT does not exist" >&2; exit 2; }
for command in mysqldump openssl tar; do command -v "$command" >/dev/null || { echo "Missing dependency: $command" >&2; exit 2; }; done
install -d -m 700 "$BACKUP_DIR"; umask 077; work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
export MYSQL_PWD="$DB_PASSWORD"
mysqldump --single-transaction --routines --triggers --user="$DB_USER" "$DB_NAME" > "$work/database.sql"
unset MYSQL_PWD
tar -czf "$work/backup.tar.gz" -C "$work" database.sql -C "$(dirname "$WP_ROOT")" "$(basename "$WP_ROOT")"
stamp=$(date -u +%Y%m%dT%H%M%SZ); output="$BACKUP_DIR/cms-$stamp.tar.gz.enc"
printf '%s' "$BACKUP_PASSPHRASE" | openssl enc -aes-256-cbc -pbkdf2 -salt -iter 200000 -pass stdin -in "$work/backup.tar.gz" -out "$output"
chmod 600 "$output"
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -pass "env:BACKUP_PASSPHRASE" -in "$output" -out "$work/verify.tar.gz"
tar -tzf "$work/verify.tar.gz" >/dev/null
sha256sum "$output" > "$output.sha256"; chmod 600 "$output.sha256"
echo "Encrypted backup verified: $output"
