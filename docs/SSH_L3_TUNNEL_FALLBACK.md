# 🔒 SSH Layer 3 Tunnel (tun10): Bulletproof CGNAT-Immune Tunnel

While WireGuard is fast and lightweight, mobile carrier CGNATs (including Jio 5G AirFiber in certain circles) aggressively drop or reset idle UDP NAT state tables after 20–30 seconds.

If you observe that WireGuard (`wg0`) sends handshakes but stalls or stops receiving inbound calls after a few minutes of quiet, OpenSSH's native **Layer 3 TUN mode (`-w 10:10`)** over standard TCP (Port 22 / 2222) is completely immune to carrier UDP dropouts.

---

## ⚡ Quick 1-Click Automated Setup

On your OpenWrt router, run our production agent:
```bash
./router-agent/setup_ssh_l3_tunnel.sh --server <YOUR_VPS_IP> --port 2222
```
This automatically provisions `/usr/bin/jio-tunnel.sh` with **Exponential Backoff and Full Jitter** and enables the `/etc/init.d/jio-vps-tunnel` procd background service.

---

## 🛡️ Exponential Backoff + Full Jitter Algorithm

Standard reconnection loops run `sleep 3` indefinitely. If the VPS reboots or network connectivity blips, a fixed-interval loop triggers a **Retry Storm**, hammering the VPS SSH daemon and risking fail2ban lockouts.

Our production daemon implements mathematical backoff:
1. **Healthy Session (>60s):** Backoff resets to `3s`.
2. **Immediate Disconnect (<60s):** Backoff doubles: $3\text{s} \rightarrow 6\text{s} \rightarrow 12\text{s} \rightarrow 24\text{s} \rightarrow \text{max } 60\text{s}$.
3. **Full Jitter:** Adds random entropy `random(0, backoff)` to prevent simultaneous reconnection collisions.

---

## 🛠️ Step 1: Enable Tunneling on your VPS (`sshd_config`)

On your cloud server (VPS):
```bash
sudo nano /etc/ssh/sshd_config
```
Ensure the following line is set:
```text
PermitTunnel yes
```
Restart SSH:
```bash
sudo systemctl restart ssh
```

### VPS Persistent Tunnel Daemon (`/etc/systemd/system/jio-tun10.service`):
```ini
[Unit]
Description=Jio Fiber Asterisk Tunnel Daemon (tun10)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/jio-tun10-daemon.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Where `/usr/local/bin/jio-tun10-daemon.sh`:
```bash
#!/bin/sh
while true; do
    if ip link show dev tun10 2>/dev/null | grep -q "DOWN"; then
        ip link set tun10 up 2>/dev/null
        ip addr flush dev tun10 2>/dev/null
        ip addr add 10.10.10.1 peer 10.10.10.2/32 dev tun10 2>/dev/null
        iptables -C INPUT -i tun10 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -i tun10 -j ACCEPT
    fi
    sleep 15
done
```

---

## 🛠️ Step 2: Verify Bidirectional Routing

Test ping across the tunnel:
```bash
# From OpenWrt router:
ping -c 2 10.10.10.1

# From VPS:
ping -c 2 10.10.10.2
```

Asterisk connects to the router endpoint (`10.10.10.2:5068`) across `tun10` with zero UDP packet loss.
