# 📱 Softphone Configuration for Global Calling

Configure your smartphone, tablet, or laptop to connect to your Asterisk PBX from anywhere in the world over cellular data (4G/5G) or public Wi-Fi.

---

## 📱 Linphone Setup (Recommended for iOS & Android)

Linphone is open-source, supports background push notifications, and handles jitter buffers cleanly.

1. Open **Linphone**.
2. Tap **Assistant > Use a SIP Account**.
3. Enter credentials:
   - **Username**: `1001`
   - **SIP Domain**: `<YOUR_VPS_PUBLIC_IP>` (e.g. `123.45.67.89` or `pbx.yourdomain.com`)
   - **Password**: `<YOUR_PASSWORD_FROM_ENV>`
   - **Transport**: `UDP` (or `TLS` on port `5061`)
4. In **Settings > Audio**:
   - Ensure `PCMA` (G.711 A-law) and `PCMU` (G.711 u-law) are enabled at top priority.
   - Optional: Enable `Opus` for high-fidelity audio over mobile networks.
5. In **Settings > Network**:
   - Enable **STUN / TURN** (use `stun.l.google.com:19302`).
   - Enable **ICE** (Interactive Connectivity Establishment).

---

## 💻 MicroSIP Setup (Windows)

1. Open **MicroSIP**.
2. Go to **Settings > Add Account**.
   - **Account Name**: `Jio Global PBX`
   - **SIP Server**: `<YOUR_VPS_PUBLIC_IP>`
   - **User**: `1002`
   - **Domain**: `<YOUR_VPS_PUBLIC_IP>`
   - **Login**: `1002`
   - **Password**: `<YOUR_PASSWORD_FROM_ENV>`
3. Set **Audio Codecs**: Check `G.711 A-law` and `G.711 u-law`.
4. Click **Save**. Status should show **Online**.

---

## 📞 How to Dial Calls

All calls are routed through your home Jio landline:

| Destination | What You Dial |
| :--- | :--- |
| **Indian Mobile Number** | `9876543210` (or `+919876543210`) |
| **STD Landline with Code** | `02212345678` or `01112345678` |
| **Toll-Free / Helpline** | `1800XXXXXXX` or `198` |
| **Extension-to-Extension** | `1001` or `1002` (Free internal call) |
