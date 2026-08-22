#!/usr/bin/env bash
set -Eeuo pipefail

# Move episode files one at a time into Season N folders.
# A completed move is the checkpoint: rerunning skips files no longer in source.

usage() {
  cat <<'EOF'
Usage:
  move-anime-seasons.sh --source DIR --destination DIR --season RANGE=SEASON ... [options]

Examples:
  # Episodes 1-20 -> Season 1, 21-40 -> Season 2
  move-anime-seasons.sh \
    --source '/lake1t/data/downloads/[Erai-raws] Bleach - 001 ~ 366 [1080p DSNP WEB-DL AVC AAC][MultiSub]' \
    --destination '/seagate4t/data/anime/Bleach' \
    --season 1-20=1 --season 21-40=2

Options:
  --delay SECONDS   Pause after each successful move (default: 2)
  --create-dirs     Create missing Season N directories (default: refuse and skip)
  --execute         Perform moves (default: dry-run)
  --log FILE        Append activity to FILE
  -h, --help        Show this help

The source is searched recursively for regular files whose name contains an
episode number like " - 001 ". RANGE and SEASON are positive integers.
EOF
}

source_dir=''
destination_dir=''
delay=2
create_dirs=false
execute=false
log_file=''
declare -a season_rules=()

die() { echo "ERROR: $*" >&2; exit 2; }

while (($#)); do
  case "$1" in
    --source) (($# >= 2)) || die "--source needs a directory"; source_dir=$2; shift 2 ;;
    --destination) (($# >= 2)) || die "--destination needs a directory"; destination_dir=$2; shift 2 ;;
    --season) (($# >= 2)) || die "--season needs RANGE=SEASON"; season_rules+=("$2"); shift 2 ;;
    --delay) (($# >= 2)) || die "--delay needs seconds"; delay=$2; shift 2 ;;
    --create-dirs) create_dirs=true; shift ;;
    --execute) execute=true; shift ;;
    --log) (($# >= 2)) || die "--log needs a file"; log_file=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (use --help)" ;;
  esac
done

[[ -n "$source_dir" && -n "$destination_dir" && ${#season_rules[@]} -gt 0 ]] || {
  usage >&2
  exit 2
}
[[ -d "$source_dir" ]] || die "source directory does not exist: $source_dir"
[[ -d "$destination_dir" ]] || die "destination series directory does not exist: $destination_dir"
[[ "$delay" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "delay must be a non-negative number"
command -v flock >/dev/null || die "flock is required (install util-linux on Linux)"

declare -a rule_start=() rule_end=() rule_season=()
for rule in "${season_rules[@]}"; do
  [[ "$rule" =~ ^([1-9][0-9]*)-([1-9][0-9]*)=([1-9][0-9]*)$ ]] || die "invalid season rule: $rule"
  start=${BASH_REMATCH[1]}; end=${BASH_REMATCH[2]}; season=${BASH_REMATCH[3]}
  ((start <= end)) || die "range starts after it ends: $rule"
  rule_start+=("$start"); rule_end+=("$end"); rule_season+=("$season")
done

if [[ -z "$log_file" ]]; then
  log_file="${destination_dir%/}/.move-anime-seasons.log"
fi

mkdir -p "$(dirname "$log_file")"
touch "$log_file" || die "cannot write log: $log_file"

# Prevent two copies from racing and producing duplicate/conflicting moves.
lock_file="${destination_dir%/}/.move-anime-seasons.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
  die "another mover is already running for $destination_dir"
fi

record() {
  local message=$1
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" | tee -a "$log_file"
}

season_for_episode() {
  local episode=$1 i
  for i in "${!rule_start[@]}"; do
    if ((episode >= rule_start[i] && episode <= rule_end[i])); then
      printf '%s\n' "${rule_season[i]}"
      return 0
    fi
  done
  return 1
}

if $execute; then
  record "START source=$source_dir destination=$destination_dir"
else
  record "DRY-RUN source=$source_dir destination=$destination_dir"
fi

moved=0
skipped=0
unassigned=0
failed=0

while IFS= read -r -d '' file; do
  name=${file##*/}
  if [[ ! "$name" =~ (^|[^0-9])([0-9]{1,4})([^0-9]|$) ]]; then
    record "SKIP no episode number: $file"
    ((skipped += 1))
    continue
  fi
  episode=$((10#${BASH_REMATCH[2]}))
  if ! season=$(season_for_episode "$episode"); then
    record "SKIP no season rule for episode $episode: $file"
    ((unassigned += 1))
    continue
  fi

  season_dir="${destination_dir%/}/Season ${season}"
  target="${season_dir%/}/$name"

  if [[ -e "$target" ]]; then
    if [[ ! -e "$file" ]]; then
      record "OK already moved: $target"
    else
      record "ERROR destination already exists; source retained: $target"
      ((failed += 1))
    fi
    continue
  fi

  if [[ ! -d "$season_dir" ]]; then
    if $create_dirs && $execute; then
      mkdir -p "$season_dir"
      record "CREATE $season_dir"
    else
      record "SKIP missing destination (use --create-dirs --execute): $season_dir"
      ((skipped += 1))
      continue
    fi
  fi

  if ! $execute; then
    record "WOULD MOVE $file -> $target"
    ((moved += 1))
    continue
  fi

  # mv is atomic when source and destination are on the same filesystem.
  if mv -- "$file" "$target"; then
    record "MOVED episode=$episode season=$season: $name"
    ((moved += 1))
    sleep "$delay"
  else
    record "ERROR move failed; source retained: $file"
    ((failed += 1))
  fi
done < <(find "$source_dir" -type f -print0)

record "DONE moved_or_planned=$moved skipped=$skipped unassigned=$unassigned failed=$failed"
((failed == 0)) || exit 1
