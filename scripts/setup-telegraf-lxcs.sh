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
#   HA_URL        Home Assistant base URL, for example http://10.0.0.30:8123
#   HA_TOKEN      Home Assistant long-lived access token
#   HA_LXC_ID     LXC that runs the Home Assistant input, default: 104

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root on the Proxmox host." >&2
  exit 1
fi

: "${INFLUX_URL:?Set INFLUX_URL, for example http://10.0.0.20:8086}"
: "${INFLUX_TOKEN:?Set INFLUX_TOKEN without committing it to Git}"
INFLUX_ORG="${INFLUX_ORG:-dacave}"
INFLUX_BUCKET="${INFLUX_BUCKET:-telegraf}"
HA_URL="${HA_URL:-}"
HA_TOKEN="${HA_TOKEN:-}"
HA_LXC_ID="${HA_LXC_ID:-104}"

if [[ -n "${HA_URL}" || -n "${HA_TOKEN}" ]]; then
  [[ -n "${HA_URL}" ]] || {
    echo "Set HA_URL when HA_TOKEN is provided" >&2
    exit 1
  }
  [[ -n "${HA_TOKEN}" ]] || {
    echo "Set HA_TOKEN when HA_URL is provided" >&2
    exit 1
  }
  [[ "${HA_URL}" != */ ]] || HA_URL="${HA_URL%/}"
  if [[ ! "${HA_LXC_ID}" =~ ^(100|101|102|103|104|105|201)$ ]]; then
    echo "HA_LXC_ID must be one of: 100 101 102 103 104 105 201" >&2
    exit 1
  fi
  ha_enabled=true
else
  ha_enabled=false
fi

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
EOF

chmod 600 "${tmp_dir}/base.conf" "${tmp_dir}/docker.conf"

if [[ "${ha_enabled}" == true ]]; then
  cat > "${tmp_dir}/homeassistant.conf" <<EOF
[[inputs.http]]
  urls = ["${HA_URL}/api/states"]
  token_file = "/etc/telegraf/telegraf.d/homeassistant.token"
  timeout = "10s"
  data_format = "json_v2"

  [[inputs.http.json_v2]]
    measurement_name = "homeassistant_state"

    [[inputs.http.json_v2.tag]]
      path = "entity_id"
    [[inputs.http.json_v2.tag]]
      path = "attributes.unit_of_measurement"
      rename = "unit_of_measurement"
      optional = true
    [[inputs.http.json_v2.tag]]
      path = "attributes.device_class"
      rename = "device_class"
      optional = true
    [[inputs.http.json_v2.field]]
      path = "state"
      type = "string"
    [[inputs.http.json_v2.field]]
      path = "attributes.friendly_name"
      rename = "friendly_name"
      type = "string"
      optional = true
EOF
  printf '%s\n' "${HA_TOKEN}" > "${tmp_dir}/homeassistant.token"
  chmod 600 "${tmp_dir}/homeassistant.conf" "${tmp_dir}/homeassistant.token"
fi

for id in 100 101 102 103 104 105 201; do
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

  if [[ "${id}" == "${HA_LXC_ID}" ]]; then
    if [[ "${ha_enabled}" == true ]]; then
      pct push "${id}" "${tmp_dir}/homeassistant.conf" /etc/telegraf/telegraf.d/homeassistant.conf
      pct push "${id}" "${tmp_dir}/homeassistant.token" /etc/telegraf/telegraf.d/homeassistant.token
      pct exec "${id}" -- chown root:telegraf \
        /etc/telegraf/telegraf.d/homeassistant.conf \
        /etc/telegraf/telegraf.d/homeassistant.token
      pct exec "${id}" -- chmod 640 \
        /etc/telegraf/telegraf.d/homeassistant.conf \
        /etc/telegraf/telegraf.d/homeassistant.token
      echo "LXC ${id}: Home Assistant metrics enabled"
    else
      pct exec "${id}" -- rm -f \
        /etc/telegraf/telegraf.d/homeassistant.conf \
        /etc/telegraf/telegraf.d/homeassistant.token
    fi
  fi

  pct exec "${id}" -- telegraf \
    --config /etc/telegraf/telegraf.conf \
    --config-directory /etc/telegraf/telegraf.d \
    --test >/dev/null
  pct exec "${id}" -- systemctl enable --now telegraf
  echo "LXC ${id}: Telegraf is running"
done

echo "Finished. Check Grafana's '${INFLUX_BUCKET}' bucket for host and Docker measurements."
