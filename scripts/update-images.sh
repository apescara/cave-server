#!/usr/bin/env bash
set -Eeuo pipefail

# Run this on the Proxmox host. The repository and Docker projects live inside
# each LXC at the same path.
readonly REPO_ROOT="/mnt/lake1t/cave-server"
readonly LOCK_FILE="/var/lock/cave-server-update-images.lock"
readonly VALID_IDS=(100 101 102 103 104 105)

usage() {
  cat <<'EOF'
Usage: update-images.sh [--check] [--all | LXC_ID ...]

  --check  Validate Compose configuration without pulling or recreating images
  --all    Update every configured LXC, continuing to the next only after the
           previous one succeeds
EOF
}

contains_id() {
  local wanted="$1"
  local id
  for id in "${VALID_IDS[@]}"; do
    [[ "$id" == "$wanted" ]] && return 0
  done
  return 1
}

check_id() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ ]] && contains_id "$id"
}

mode="update"
ids=()
for arg in "$@"; do
  case "$arg" in
    --check) mode="check" ;;
    --all) ids=("${VALID_IDS[@]}") ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
    *)
      check_id "$arg" || { echo "Unsupported LXC ID: $arg" >&2; exit 2; }
      ids+=("$arg")
      ;;
  esac
done

if ((${#ids[@]} == 0)); then
  echo "Choose an LXC ID or use --all." >&2
  usage >&2
  exit 2
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root on the Proxmox host." >&2
  exit 1
fi

command -v pct >/dev/null || { echo "pct is required." >&2; exit 1; }
command -v flock >/dev/null || { echo "flock is required." >&2; exit 1; }

exec 9>"$LOCK_FILE"
flock -n 9 || {
  echo "Another image update is already running." >&2
  exit 1
}

failed=()
for id in "${ids[@]}"; do
  echo "=== LXC $id: ${mode} ==="
  if ! pct exec "$id" -- bash -s -- "$REPO_ROOT/docker/$id" "$mode" <<'REMOTE'
set -Eeuo pipefail
project="$1"
mode="$2"

cd "$project"
docker compose version >/dev/null
docker compose config --quiet

if [[ "$mode" == "check" ]]; then
  echo "Compose configuration is valid: $project"
  exit 0
fi

echo "Images before update:"
docker compose images
docker compose pull
docker compose up -d --remove-orphans
echo "Services after update:"
docker compose ps
REMOTE
  then
    echo "LXC $id failed; no further action was taken in that LXC." >&2
    failed+=("$id")
  fi
done

if ((${#failed[@]} > 0)); then
  echo "Failed LXCs: ${failed[*]}" >&2
  exit 1
fi

echo "Image update completed successfully."
