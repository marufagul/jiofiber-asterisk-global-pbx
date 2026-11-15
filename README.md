# 🌍 JioFiber Asterisk Global PBX Gateway

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Asterisk 20 LTS](https://img.shields.io/badge/Asterisk-20%20LTS-orange.svg?logo=asterisk)](https://www.asterisk.org/)
[![Docker Ready](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](docker-compose.yml)
[![WireGuard](https://img.shields.io/badge/Tunnel-WireGuard-88171A?logo=wireguard&logoColor=white)](router-agent/)
[![Global Calling](https://img.shields.io/badge/Calls-Worldwide%20Zero%20Roaming-brightgreen)](#)

**Turn your Jio home landline into a global cloud PBX. Make and receive calls on your smartphone from anywhere in the world with zero roaming charges.**

[Quick Start](#-quick-start-in-5-minutes) • [Architecture](#-architecture) • [Feature Matrix](#-feature-matrix) • [Softphone Setup](#-softphone-configuration) • [Security](#-security--hardening)

</div>

---

> [!TIP]
> **Using an AI Coding Assistant? (Claude Code, Gemini CLI, Cursor, Windsurf)**  
> Deploy your cloud PBX automatically by pasting this prompt into your agent terminal:  
> ```text
> "Connect to my VPS via SSH. Verify Docker and Docker Compose are installed. Clone https://github.com/marufagul/jiofiber-asterisk-global-pbx, configure .env with my Jio landline number and a strong SIP password, start the Asterisk PBX container via docker-compose up -d, and generate the WireGuard client configuration for my OpenWrt home router."
> ```

---

## ⚡ Quick Start in 5 Minutes

### Step 1: Deploy Asterisk PBX on your VPS

```bash
git clone https://github.com/marufagul/jiofiber-asterisk-global-pbx.git
cd jiofiber-asterisk-global-pbx
cp .env.example .env
# Edit .env with your landline number and chosen extension passwords:
nano .env

# Start Asterisk PBX stack
docker compose up -d
```

### Step 2: Connect your Home OpenWrt Router

On your OpenWrt router, run the reverse tunnel agent:
```bash
wget -O - https://raw.githubusercontent.com/marufagul/jiofiber-asterisk-global-pbx/main/router-agent/setup_router_tunnel.sh | sh -s -- --server <YOUR_VPS_IP>
```

### Step 3: Register Softphone Anywhere in the World

Open Linphone or MicroSIP on your iPhone / Android / Laptop:
- **Server**: `<YOUR_VPS_IP>:5060` (or TLS `5061`)
- **Username**: `1001`
- **Password**: `<PASSWORD_FROM_ENV>`

Dial any mobile or landline number — your call originates through your Jio landline at home with 0 roaming charges!

---

## 🏗️ Architecture

```
  ┌──────────────────────────────────────────────────────────────┐
  │                 ANYWHERE IN THE WORLD (4G/5G/Wi-Fi)          │
  │                                                              │
  │   [Your Smartphone: Linphone]       [Your Laptop: MicroSIP]  │
  │                  │                             │             │
  │                  └──────────────┬──────────────┘             │
  │                                 │ SIP / TLS / SRTP           │
  └─────────────────────────────────┼────────────────────────────┘
                                    │
                                    ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                    YOUR CLOUD VPS / SERVER                   │
  │                                                              │
  │   • Asterisk 20 LTS PBX (Docker Container)                   │
  │   • Extensions Engine (1001, 1002, Simultaneous Ringing)     │
  │   • WireGuard Encrypted Tunnel Hub                           │
  └─────────────────────────────────┬────────────────────────────┘
                                    │
                         WireGuard Encrypted Tunnel
                                    │
                                    ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                 YOUR HOME OPENWRT ROUTER                     │
  │                                                              │
  │   • WireGuard Peer Interface (wg0)                           │
  │   • nftables Transparent Voice Forwarder                     │
  │   • Dedicated Voice Interface (eth0.406)                     │
  └─────────────────────────────────┬────────────────────────────┘
                                    │
                        Jio IMS Voice VLAN 406
                                    │
                                    ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                 RELIANCE JIO IMS CORE NETWORK                │
  │                 (Local Fixed Line Telephone)                 │
  └──────────────────────────────────────────────────────────────┘
```

---

## 📊 Feature Matrix

| Capability | Official JioJoin App | This Asterisk Global PBX |
| :--- | :---: | :---: |
| **Calls over Home Wi-Fi** | ✅ Yes | ✅ Yes |
| **Calls over Mobile 4G/5G Anywhere** | ❌ Blocked | ✅ Full Worldwide Access |
| **International Roaming Charges** | ❌ High or N/A | ✅ **Zero Roaming Costs** |
| **Multiple Extensions Ring Simultaneously** | ❌ No | ✅ Yes (iPhone + Android + Laptop) |
| **Call Recording & CDR Logs** | ❌ No | ✅ Full Automated Recording |
| **Voicemail to Email** | ❌ No | ✅ Built-in Asterisk Voicemail |
| **Compatible Softphones** | Only JioJoin App | Any SIP Client (Linphone, Acrobits, MicroSIP) |
| **Encrypted Media (TLS / SRTP)** | ❌ No | ✅ Enterprise Encryption |

---

## 🔒 Security & Hardening

Exposing a SIP server to the public Internet without protection invites automated scanners. This stack comes pre-hardened:
- **Private WireGuard Tunnel**: The softphone can optionally connect entirely over WireGuard VPN with SIP ports closed to the public Internet.
- **Fail2ban Integration**: Auto-bans brute-force attempts on SIP UDP/TCP.
- **SRTP Media Encryption**: Calls between your smartphone and the PBX are encrypted against eavesdropping.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
