#!/usr/bin/env bash
# Audit permissions. --fix is intentionally explicit and changes filesystem modes.
set -Eeuo pipefail
ROOT="${1:-/var/www/html}"; MODE="${2:---audit}"
[[ -d "$ROOT" ]] || { echo "ERROR: directory not found: $ROOT" >&2; exit 2; }
[[ "$MODE" == "--audit" || "$MODE" == "--fix" ]] || { echo "Usage: $0 ROOT [--audit|--fix]" >&2; exit 2; }
REPORT="${REPORT_FILE:-permissions-$(date +%F-%H%M%S).csv}"
echo 'path,type,mode,owner,group,status' > "$REPORT"
while IFS= read -r -d '' path; do
  if [[ -d "$path" ]]; then expected=755; type=directory; else expected=644; type=file; fi
  status=OK
  if [[ "$MODE" == "--fix" ]]; then chmod "$expected" "$path"; status=FIXED
  elif [[ "$(stat -c '%a' "$path")" == 777 || "$(stat -c '%a' "$path")" == 666 ]]; then status=UNSAFE; fi
  printf '"%s",%s,%s,%s,%s,%s\n' "$path" "$type" "$(stat -c '%a' "$path")" "$(stat -c '%U' "$path")" "$(stat -c '%G' "$path")" "$status" >> "$REPORT"
done < <(find "$ROOT" -xdev \( -type f -o -type d \) -print0)
if [[ -f "$ROOT/wp-config.php" ]]; then
  [[ "$MODE" != "--fix" ]] || chmod 400 "$ROOT/wp-config.php"
  echo "wp-config.php mode=$(stat -c '%a' "$ROOT/wp-config.php")"
fi
echo "Report: $REPORT"
