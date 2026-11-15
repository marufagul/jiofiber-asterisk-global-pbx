#!/bin/sh
# ==============================================================================
# JioFiber Asterisk Global PBX - Automated Setup Wizard
# Author: Gul Marufa (@marufagul)
# https://github.com/marufagul/jiofiber-asterisk-global-pbx
# ==============================================================================

set -e

echo "=========================================================="
echo "🌍 JioFiber Asterisk Global PBX Setup Wizard"
echo "   Developed by Gul Marufa (@marufagul)"
echo "=========================================================="

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "[+] Created .env from template."
    fi
fi

# Check for Docker and Docker Compose
if ! command -v docker >/dev/null 2>&1; then
    echo "[-] Error: Docker is not installed. Please install Docker first:"
    echo "    curl -fsSL https://get.docker.com | sh"
    exit 1
fi

echo ""
echo "Please enter your configuration details:"
printf "Enter your Jio Fixed Line Number (e.g. +912212345678): "
read -r USER_JIO_NUM

printf "Enter password for Softphone 1001 (Your Mobile): "
read -r USER_PASS_1001

printf "Enter password for Softphone 1002 (Your Laptop): "
read -r USER_PASS_1002

# Get Public IP
DETECTED_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || echo "127.0.0.1")
printf "Enter your VPS Public IP [%s]: " "$DETECTED_IP"
read -r USER_VPS_IP
if [ -z "$USER_VPS_IP" ]; then
    USER_VPS_IP="$DETECTED_IP"
fi

# Write .env file
cat <<EOF > .env
JIO_LANDLINE_NUMBER=${USER_JIO_NUM}
EXT_1001_PASSWORD=${USER_PASS_1001}
EXT_1002_PASSWORD=${USER_PASS_1002}
VPS_PUBLIC_IP=${USER_VPS_IP}
EOF

# Update pjsip.conf with user credentials
if [ -f asterisk/pjsip.conf ]; then
    sed -i "s/ChangeThisSecretKey123!/${USER_PASS_1001}/g" asterisk/pjsip.conf
    sed -i "s/ChangeThisSecondSecretKey456!/${USER_PASS_1002}/g" asterisk/pjsip.conf
fi

# Update extensions.conf with user phone number
if [ -f asterisk/extensions.conf ]; then
    sed -i "s/MY_JIO_NUMBER=+91XXXXXXXXXX/MY_JIO_NUMBER=${USER_JIO_NUM}/g" asterisk/extensions.conf
fi

echo "[+] Configurations successfully synchronized."

echo "[*] Launching Asterisk PBX container via Docker Compose..."
docker compose up -d

echo ""
echo "=========================================================="
echo "🎉 SUCCESS: Your JioFiber Global PBX is now running!"
echo "=========================================================="
echo "• PBX Host:               ${USER_VPS_IP}:5060"
echo "• Mobile Extension:       1001 (Password: ${USER_PASS_1001})"
echo "• Laptop Extension:       1002 (Password: ${USER_PASS_1002})"
echo "• Reverse Tunnel Script:  ./router-agent/setup_router_tunnel.sh"
echo "=========================================================="
