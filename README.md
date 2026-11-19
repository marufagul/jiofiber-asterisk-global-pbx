# 🌍 JioFiber Asterisk Global PBX Gateway

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Asterisk 20 LTS](https://img.shields.io/badge/Asterisk-20%20LTS-orange.svg?logo=asterisk)](https://www.asterisk.org/)
[![Docker Ready](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](docker-compose.yml)
[![WireGuard](https://img.shields.io/badge/Tunnel-WireGuard-88171A?logo=wireguard&logoColor=white)](router-agent/)
[![Global Calling](https://img.shields.io/badge/Calls-Worldwide%20Zero%20Roaming-brightgreen)](#)

**Turn your Jio home landline into a global cloud PBX. Make and receive calls on your smartphone from anywhere in the world with zero roaming charges.**

[Why I Built This](#-why-i-built-this-a-note-from-the-author) • [Quick Start](#-quick-start-in-5-minutes) • [Architecture](#-architecture) • [Feature Matrix](#-feature-matrix) • [Softphone Setup](#-softphone-configuration) • [Security](#-security--hardening)

</div>

---

> [!TIP]
> ### 📦 Complete Jio OpenWrt Ecosystem Suite
> • 🌍 **Global Cloud Asterisk PBX:** [jiofiber-asterisk-global-pbx](https://github.com/marufagul/jiofiber-asterisk-global-pbx) *(This Repo - Zero roaming landline calling on your phone worldwide)*  
> • 🚀 **5G WAN & Wi-Fi 6 Engine:** [jio-airfiber-openwrt-5g-wan](https://github.com/marufagul/jio-airfiber-openwrt-5g-wan) *(2.5G Wire-Speed, 464XLAT & HE160 Wi-Fi for JIDU6401)*  
> • 📞 **Home Landline Voice Gateway:** [openwrt-jiofiber-voice-lan](https://github.com/marufagul/openwrt-jiofiber-voice-lan) *(Free landline calls over Wi-Fi via JioJoin & SIP)*

---

## 💡 Why I Built This (A Note from the Author)

Reliance Jio provides a complimentary unlimited fixed-line landline number with every fiber and AirFiber broadband plan. But they deliberately lock that landline inside their proprietary JioJoin app, which refuses to work unless you are physically connected to your home Wi-Fi network.

When traveling abroad or outside my home, I wanted to be able to make calls back home to India and answer incoming calls on my iPhone and laptop without incurring crippling international roaming charges.

**I searched the internet, forums, and GitHub, and couldn't find a single person who had solved or shared how to liberate this.**

We invested hundreds of hours reverse-engineering:
- Jio's IMS network SIP registration parameters and P-Preferred-Identity routing.
- The 464XLAT and IPv6 routing requirements between cloud VPS servers and local home gateways.
- Low-latency WireGuard tunneling configurations designed to carry real-time voice packets with zero packet jitter.

**We are giving this entire production PBX stack away 100% free and open-source.** If this project saves you money and liberates your landline, please show your support with a ⭐ star on GitHub!

— **Gul Marufa ([@marufagul](https://github.com/marufagul))**

---

> [!TIP]
> **Using an AI Coding Assistant? (Claude Code, Gemini CLI, Cursor, Windsurf)**  
> Deploy your cloud PBX automatically by pasting this prompt into your agent terminal:  
> ```text
> "Connect to my VPS via SSH. Verify Docker and Docker Compose are installed. Clone https://github.com/marufagul/jiofiber-asterisk-global-pbx, run ./setup.sh to configure my landline number and extensions, start the Asterisk PBX container, and generate the WireGuard client configuration for my OpenWrt home router."
> ```

---

## ⚡ Quick Start in 5 Minutes

### Step 1: Deploy Asterisk PBX on your VPS

```bash
git clone https://github.com/marufagul/jiofiber-asterisk-global-pbx.git
cd jiofiber-asterisk-global-pbx
chmod +x setup.sh
./setup.sh
```
The interactive wizard prompts for your phone number and passwords, synchronizes the configuration files, and launches the container stack.

### Step 2: Connect your Home OpenWrt Router

On your OpenWrt router, choose your tunnel transport:

* **Option A: WireGuard Tunnel (FTTH / High Performance):**
  ```bash
  wget -O - https://raw.githubusercontent.com/marufagul/jiofiber-asterisk-global-pbx/main/router-agent/setup_router_tunnel.sh | sh -s -- --server <YOUR_VPS_IP>
  ```

* **Option B: SSH Layer 3 Tunnel with Exponential Backoff + Jitter (Recommended for 5G AirFiber / CGNAT):**
  ```bash
  wget -O - https://raw.githubusercontent.com/marufagul/jiofiber-asterisk-global-pbx/main/router-agent/setup_ssh_l3_tunnel.sh | sh -s -- --server <YOUR_VPS_IP> --port 2222
  ```
  *(See [SSH Layer 3 Tunnel Guide](docs/SSH_L3_TUNNEL_FALLBACK.md) for details on why TCP port 2222 bypasses carrier UDP drops).*

> [!NOTE]
> **Router SIP Trunk Prerequisites:**  
> The Asterisk PBX routes landline calls through your router at `10.10.10.2:5068`. Ensure your router has its local IMS voice daemon (`hgw-voice-app`) or SIP bridge active. Read our [Trunk Prerequisites & HGW Bridge Guide](docs/TRUNK_PREREQUISITES_AND_HGW_BRIDGE.md).

### Step 3: Register Softphone Anywhere in the World

Open Linphone or MicroSIP on your iPhone / Android / Laptop:
- **Server**: `<YOUR_VPS_IP>:5060` (or TLS `5061`)
- **Username**: `1001`
- **Password**: `<PASSWORD_ENTERED_IN_SETUP>`

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
- **Fail2ban Integration**: Auto-bans brute-force attempts on SIP UDP/TCP. See [Security Hardening Guide](docs/SECURITY_HARDENING.md).
- **SRTP Media Encryption**: Calls between your smartphone and the PBX are encrypted against eavesdropping.

---

## 🔧 Cellular Carrier CGNAT & Tunneling Troubleshooting

> [!TIP]
> **Carrier CGNAT Dropping WireGuard UDP?**  
> In certain circles, cellular 5G carriers drop persistent unestablished UDP traffic, causing WireGuard handshakes to stall.  
> We have included a full guide and automation script for our bulletproof **SSH Layer 3 Tunnel (`tun10`)** running over TCP 2222:  
> 👉 [Read the SSH Layer 3 Tunnel Guide](docs/SSH_L3_TUNNEL_FALLBACK.md)

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
