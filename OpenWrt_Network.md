# This tutorial is for initialising the network settings of a fresh install of OpenWrt.

# 1. Enter OpenWrt shell

## 1st Method:

Use Vim to edit the network configuration

```
vi /etc/config/network
```

How to operate in Vi:

```
1) Press i to enter insert mode.
2) Edit the LAN address.
3) Press Esc to return to view mode.
4) Type :wq to write the changes and quit.
```

## 2nd Method

Use uci command to edit the network configuration.

```
1) uci show network
This is to check the current network configuration.
2) uci set network.lan.ipaddr='192.168.3.11' (whatever address you want)
This is to change the LAN address.
```

# 2. Confirm the network setting changes (IMPORTANT!!!)

```
uci commit
```

# 3. Restart the network service to apply the changes

```
service network restart
```

# 4. Visit the LuCI page

Type the LAN address into the address bar of your browser to visit LuCI (the web GUI for OpenWrt management) to make further configurations.

# 5. Reconnect the WAN interface, if PPPoE is used

After setting up PPPoE, reconnect the WAN interface. Otherwise, net speed could be slower than expected.

# NB

Use the 'arp' command to check clients connected to OpenWrt. This will show the MAC address, IP address, and interface (device) for all clients connected to the router.
