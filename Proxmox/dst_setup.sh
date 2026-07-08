#!/usr/bin/env sh
set -eu

: "${DST_CLUSTER_TOKEN:?DST_CLUSTER_TOKEN is required}"
DST_CLUSTER_PASSWORD="${DST_CLUSTER_PASSWORD:-}"

SAVE_ROOT="/data/save"
MODS_ROOT="/data/mods"
UGC_ROOT="/data/ugc_mods"
CLUSTER_DIR="${SAVE_ROOT}/Cluster_1"
MASTER_DIR="${CLUSTER_DIR}/Master"
CAVES_DIR="${CLUSTER_DIR}/Caves"

mkdir -p "${MASTER_DIR}" "${CAVES_DIR}" "${MODS_ROOT}" "${UGC_ROOT}"

touch "${MODS_ROOT}/dedicated_server_mods_setup.lua"
touch "${MODS_ROOT}/modsettings.lua"

printf '%s\n' "${DST_CLUSTER_TOKEN}" > "${CLUSTER_DIR}/cluster_token.txt"

cat > "${CLUSTER_DIR}/cluster.ini" << EOF
[GAMEPLAY]
game_mode = [your shit here]
max_players = [your shit here]
pvp = true
pause_when_empty = true

[NETWORK]
cluster_description = [your shit here]
cluster_name = [your shit here]
cluster_intention = cooperative
cluster_password = ${DST_CLUSTER_PASSWORD}

[MISC]
console_enabled = true

[SHARD]
shard_enabled = true
bind_ip = 0.0.0.0
master_ip = dst-master
master_port = 10888
cluster_key = dst_secret_key
EOF

cat > "${MASTER_DIR}/server.ini" << 'EOF'
[NETWORK]
server_port = 10999

[SHARD]
is_master = true

[STEAM]
master_server_port = 27018
authentication_port = 27019
EOF

cat > "${MASTER_DIR}/worldgenoverride.lua" << 'EOF'
return {
    override_enabled = true,
    preset = "SURVIVAL_TOGETHER"
}
EOF

cat > "${CAVES_DIR}/server.ini" << 'EOF'
[NETWORK]
server_port = 11000

[SHARD]
is_master = false
name = Caves

[STEAM]
master_server_port = 27020
authentication_port = 27021
EOF

cat > "${CAVES_DIR}/worldgenoverride.lua" << 'EOF'
return {
    override_enabled = true,
    preset = "DST_CAVES"
}
EOF

echo "DST config initialized at ${CLUSTER_DIR}"
