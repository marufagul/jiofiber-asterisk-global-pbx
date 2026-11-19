# 📞 Asterisk PBX Trunk Prerequisites & OpenWrt Voice Bridge

This technical reference explains how the Asterisk PBX connects to your home OpenWrt router, how the SIP trunk handshake functions, and how to satisfy the local router-side prerequisites.

---

## Architecture Overview

```
  ┌─────────────────────────────────────────────────────────────┐
  │                 ANYWHERE IN THE WORLD                       │
  │   [Your Smartphone / Laptop: Linphone / MicroSIP]           │
  └──────────────────────────────┬──────────────────────────────┘
                                 │ SIP TLS / SRTP (Port 5061)
  ┌──────────────────────────────▼──────────────────────────────┐
  │                 YOUR CLOUD VPS (ASTERISK 20)                │
  │                                                             │
  │   • Extensions 1001 & 1002 (Simultaneous Ringing)           │
  │   • PJSIP Trunk: [jio-trunk]                                │
  │   • Outbound Proxy: sip:10.10.10.2:5068;transport=tls;lr   │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                 WireGuard / SSH L3 Tunnel (tun10)
                                 │
  ┌──────────────────────────────▼──────────────────────────────┐
  │                 YOUR OPENWRT HOME ROUTER                    │
  │                                                             │
  │   • Tunnel IP: 10.10.10.2                                   │
  │   • Voice Gateway Daemon: hgw-voice-app (Port 5068 TLS)     │
  │   • TR-069 Provisioning XML: /etc/juice/FixedVoiceCcsXML.dat│
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                     Jio 5G IMS Core Network
```

---

## 1. What Asterisk Expects at `10.10.10.2:5068`

In `asterisk/pjsip.conf`:
```ini
[jio-trunk]
type=endpoint
context=from-jio
transport=transport-tls
disallow=all
allow=alaw,ulaw
aors=jio-trunk-aor
outbound_proxy=sip:10.10.10.2:5068\;transport=tls\;lr
contact_header_params=+sip.instance="<urn:uuid:00000000-0000-1000-8000-020000112233>"
```

Asterisk sends all outbound landline calls to `10.10.10.2:5068` over the private tunnel. 
On your OpenWrt router, **port 5068 must be listening and ready to accept SIP TLS connections**.

---

## 2. Router-Side Setup: Running `hgw-voice-app`

The local SIP bridge on port 5068 is powered by the Sercomm / Jio IMS daemon (`hgw-voice-app`), which handles authentication with Jio's cellular core:

### Required Files (from Stock Firmware Backup):
1. **Juice Binary Bundle (`/root/juice_bundle.tar.gz`):**
   Contains `/tmp/juice/hgw-voice-app`, `libims`, `ont_dc`, and `libnossl.so` (to bypass SSL pinning).
2. **Fixed Voice Provisioning XML (`/etc/juice/FixedVoiceCcsXML.dat`):**
   Contains your landline number, IMS realm, and P-CSCF tokens.
3. **Hardware Identifiers in `/tmp/`:**
   ```sh
   # IMPORTANT: Replace with YOUR serial number and WAN MAC from the bottom sticker of your router!
   echo "JIDU6401" > /tmp/deviceModel
   echo "RSVHGHKW00XXXXX" > /tmp/deviceSerial       # <--- YOUR Serial Number from bottom sticker
   echo "SRCMJIO_JIDU6401_R2.0.9" > /tmp/firmVersion
   echo "9c:d4:a6:xx:xx:xx" > /tmp/wanMAC           # <--- YOUR WAN MAC from bottom sticker
   mkdir -p /tmp/cpe3
   echo "JIDU6401" > /tmp/cpe3/dps.productclass
   ```

Once started via `/etc/init.d/hgw-voice start`, `hgw-voice-app` listens on port 5068. The moment Asterisk forwards a call over the tunnel, `hgw-voice-app` routes it directly through Jio's IMS network with zero latency.
