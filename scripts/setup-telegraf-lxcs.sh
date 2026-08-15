#!/usr/bin/env bash
set -Eeuo pipefail

# Run this script on the Proxmox host as root.
# It configures Telegraf in LXCs 100 through 105.
#
# Required environment variables:
#   INFLUX_URL   e.g. http://10.0.0.20:8086
#   INFLUX_TOKEN
#
# Optional:
#   INFLUX_ORG    default: dacave
#   INFLUX_BUCKET default: telegraf

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root on the Proxmox host." >&2
  exit 1
fi

: "${INFLUX_URL:?Set INFLUX_URL, for example http://10.0.0.20:8086}"
: "${INFLUX_TOKEN:?Set INFLUX_TOKEN without committing it to Git}"
INFLUX_ORG="${INFLUX_ORG:-dacave}"
INFLUX_BUCKET="${INFLUX_BUCKET:-telegraf}"

for command_name in pct mktemp; do
  command -v "${command_name}" >/dev/null || {
    echo "Missing required command: ${command_name}" >&2
    exit 1
  }
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

cat > "${tmp_dir}/base.conf" <<EOF
[agent]
  interval = "15s"
  round_interval = true
  flush_interval = "15s"
  hostname = ""

[[outputs.influxdb_v2]]
  urls = ["${INFLUX_URL}"]
  token = "${INFLUX_TOKEN}"
  organization = "${INFLUX_ORG}"
  bucket = "${INFLUX_BUCKET}"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  report_active = true

[[inputs.mem]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.processes]]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "squashfs", "proc", "sysfs", "cgroup", "cgroup2"]

[[inputs.diskio]]
[[inputs.net]]
[[inputs.kernel]]
EOF

cat > "${tmp_dir}/docker.conf" <<'EOF'
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  timeout = "5s"
  perdevice = true
  total = true
EOF

chmod 600 "${tmp_dir}/base.conf" "${tmp_dir}/docker.conf"

for id in 100 101 102 103 104 105 106; do
  if ! pct status "${id}" >/dev/null 2>&1; then
    echo "LXC ${id}: does not exist; skipping"
    continue
  fi

  status="$(pct status "${id}")"
  if [[ "${status}" != *"status: running"* ]]; then
    echo "LXC ${id}: ${status}; skipping"
    continue
  fi

  echo "LXC ${id}: installing/configuring Telegraf"
  pct exec "${id}" -- bash -s <<'REMOTE_SCRIPT'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if ! command -v telegraf >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -d -m 0755 /etc/apt/keyrings

  key_file="/tmp/influxdata-archive.key"
  curl --fail --silent --show-error --location \
    -o "${key_file}" \
    https://repos.influxdata.com/influxdata-archive.key

  gpg --show-keys --with-fingerprint --with-colons "${key_file}" 2>&1 \
    | grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$'

  gpg --dearmor --yes \
    --output /etc/apt/keyrings/influxdata-archive.gpg "${key_file}"
  rm -f "${key_file}"

  printf '%s\n' \
    'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
    > /etc/apt/sources.list.d/influxdata.list

  apt-get update
  apt-get install -y telegraf
fi

install -d -m 755 /etc/telegraf/telegraf.d
REMOTE_SCRIPT

  pct push "${id}" "${tmp_dir}/base.conf" /etc/telegraf/telegraf.d/metrics.conf
  pct exec "${id}" -- chown root:telegraf /etc/telegraf/telegraf.d/metrics.conf
  pct exec "${id}" -- chmod 640 /etc/telegraf/telegraf.d/metrics.conf

  if pct exec "${id}" -- test -S /var/run/docker.sock; then
    pct exec "${id}" -- bash -s <<'REMOTE_DOCKER_PERMISSIONS'
set -Eeuo pipefail
if getent group docker >/dev/null 2>&1; then
  usermod -aG docker telegraf
fi
REMOTE_DOCKER_PERMISSIONS
    pct push "${id}" "${tmp_dir}/docker.conf" /etc/telegraf/telegraf.d/docker.conf
    pct exec "${id}" -- chown root:telegraf /etc/telegraf/telegraf.d/docker.conf
    pct exec "${id}" -- chmod 640 /etc/telegraf/telegraf.d/docker.conf
    echo "LXC ${id}: Docker socket found; Docker metrics enabled"
  else
    pct exec "${id}" -- rm -f /etc/telegraf/telegraf.d/docker.conf
    echo "LXC ${id}: no Docker socket; host metrics only"
  fi

  pct exec "${id}" -- telegraf \
    --config /etc/telegraf/telegraf.conf \
    --config-directory /etc/telegraf/telegraf.d \
    --test >/dev/null
  pct exec "${id}" -- systemctl enable --now telegraf
  echo "LXC ${id}: Telegraf is running"
done

echo "Finished. Check Grafana's '${INFLUX_BUCKET}' bucket for host and Docker measurements."
