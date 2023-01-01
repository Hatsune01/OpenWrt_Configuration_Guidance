#Networking #Homelab 

---
> SSH into OpenWrt first.
---

# 1. Edit network configurations

## Method 1:
Edit directly.
```bash
vi /etc/config/network
```

## 2nd Method
Use the uci command to edit the network configuration.

```bash
uci show network
# Check the current network configuration.
uci set network.lan.ipaddr='192.168.3.11'
# Set to whatever address you want.
# Change the LAN address.
```

# 2. Confirm the network setting changes (IMPORTANT!!!)

```
uci commit
```

# 3. Restart the network services

```
service network restart
```

# 4. Reconnect the WAN interface if PPPoE is used
After setting up PPPoE, reconnect the WAN interface. Otherwise, network speed could be slower than expected.

> Use the `arp` command to check clients connected to OpenWrt. This will show the MAC address, IP address, and interface (device) for all connected clients.
