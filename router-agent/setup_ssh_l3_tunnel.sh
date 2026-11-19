#!/bin/sh
# ==============================================================================
# OpenWrt Router Agent - CGNAT-Proof SSH Layer 3 Tunnel (tun10)
# Developed by Gul Marufa (@marufagul)
# https://github.com/marufagul/jiofiber-asterisk-global-pbx
#
# Features:
#   • Bypasses Cellular 5G CGNAT UDP dropouts over TCP port 2222
#   • Exponential Backoff (3s -> 6s -> 12s -> 24s -> 60s) with Full Jitter
#   • Prevents Retry Storms and Dropbear authentication lockouts
#   • Resilient automatic lifecycle supervision
# ==============================================================================

set -e

VPS_HOST=""
VPS_PORT="2222"
SSH_KEY="/root/.ssh/id_ed25519"
ROUTER_TUN_IP="10.10.10.2"
VPS_TUN_IP="10.10.10.1"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --server) VPS_HOST="$2"; shift 2;;
        --port) VPS_PORT="$2"; shift 2;;
        --key) SSH_KEY="$2"; shift 2;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
done

if [ -z "$VPS_HOST" ]; then
    echo "Usage: $0 --server <VPS_PUBLIC_IP> [--port 2222] [--key /root/.ssh/id_ed25519]"
    exit 1
fi

echo "[*] Configuring Layer 3 SSH Tunnel daemon to Asterisk VPS at $VPS_HOST:$VPS_PORT..."

# 1. Ensure SSH client and keys are present
if [ ! -f "$SSH_KEY" ]; then
    echo "[*] Generating Ed25519 SSH identity key at $SSH_KEY..."
    mkdir -p /root/.ssh
    dropbearkey -t ed25519 -f "$SSH_KEY" 2>/dev/null || ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"
fi

# 2. Deploy the daemon script to /usr/bin/jio-tunnel.sh
cat << 'EOF' > /usr/bin/jio-tunnel.sh
#!/bin/sh
# Jio VPS Tunnel Daemon (tun10) with Exponential Backoff + Full Jitter

BASE_BACKOFF=3
MAX_BACKOFF=60
CURRENT_BACKOFF=$BASE_BACKOFF

setup_tun10() {
    ip link set tun10 up 2>/dev/null
    ip addr flush dev tun10 2>/dev/null
    ip addr add 10.10.10.2 peer 10.10.10.1/32 dev tun10 2>/dev/null
    ip -6 addr add fd00:10:10::2/64 dev tun10 2>/dev/null
    ip route replace 10.10.10.0/24 dev tun10 2>/dev/null
}

calc_jitter() {
    local max=$1
    [ "$max" -le 1 ] && echo 1 && return
    local r
    r=$(hexdump -n 2 -e '/2 "%u"' /dev/urandom 2>/dev/null)
    [ -z "$r" ] && r=$(( $(date +%s) + $$ ))
    echo $(( (r % max) + 1 ))
}

while true; do
    (
        while true; do
            if ip link show dev tun10 >/dev/null 2>&1; then
                if ! ip -4 addr show dev tun10 2>/dev/null | grep -q '10.10.10.2'; then
                    setup_tun10
                fi
            fi
            sleep 15
        done
    ) &
    TUN_PID=$!

    START_TS=$(date +%s)
    /usr/bin/ssh -N -w 10:10 -i __SSH_KEY__ -p __VPS_PORT__ root@__VPS_HOST__ \
        -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no
    END_TS=$(date +%s)

    kill $TUN_PID 2>/dev/null
    wait $TUN_PID 2>/dev/null

    DURATION=$(( END_TS - START_TS ))
    if [ "$DURATION" -ge 60 ]; then
        CURRENT_BACKOFF=$BASE_BACKOFF
    fi

    JITTER=$(calc_jitter "$CURRENT_BACKOFF")
    SLEEP_SECS=$(( (CURRENT_BACKOFF / 2) + (JITTER / 2) + 1 ))
    [ "$SLEEP_SECS" -gt "$MAX_BACKOFF" ] && SLEEP_SECS=$MAX_BACKOFF

    logger -t jio-tunnel "Tunnel session ended after ${DURATION}s. Reconnecting in ${SLEEP_SECS}s (backoff window: ${CURRENT_BACKOFF}s)..."

    CURRENT_BACKOFF=$(( CURRENT_BACKOFF * 2 ))
    [ "$CURRENT_BACKOFF" -gt "$MAX_BACKOFF" ] && CURRENT_BACKOFF=$MAX_BACKOFF

    sleep "$SLEEP_SECS"
done
EOF

sed -i "s|__SSH_KEY__|$SSH_KEY|g" /usr/bin/jio-tunnel.sh
sed -i "s|__VPS_PORT__|$VPS_PORT|g" /usr/bin/jio-tunnel.sh
sed -i "s|__VPS_HOST__|$VPS_HOST|g" /usr/bin/jio-tunnel.sh
chmod +x /usr/bin/jio-tunnel.sh

# 3. Register procd init service
cat << 'EOF' > /etc/init.d/jio-vps-tunnel
#!/bin/sh /etc/rc.common
USE_PROCD=1
START=95
STOP=10

start_service() {
    procd_open_instance jio-vps-tunnel
    procd_set_param command /usr/bin/jio-tunnel.sh
    procd_set_param respawn 3600 5 0
    procd_close_instance
}

stop_service() {
    killall jio-tunnel.sh 2>/dev/null
}
EOF

chmod +x /etc/init.d/jio-vps-tunnel
/etc/init.d/jio-vps-tunnel enable 2>/dev/null || true
/etc/init.d/jio-vps-tunnel restart 2>/dev/null || true

# 4. Open nftables firewall for tun10
nft insert rule inet fw4 input iifname 'tun10' accept 2>/dev/null || true

echo ""
echo "=========================================================="
echo "🎉 SUCCESS: SSH Layer 3 Tunnel Service Active!"
echo "=========================================================="
echo "• Target VPS:             $VPS_HOST:$VPS_PORT"
echo "• Tunnel Interface:       tun10 (Router: 10.10.10.2 <-> VPS: 10.10.10.1)"
echo "• Reconnect Algorithm:    Exponential Backoff with Full Jitter"
echo "• Service Name:           /etc/init.d/jio-vps-tunnel"
echo "=========================================================="
