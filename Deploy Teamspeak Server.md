---
categories:
- Sysadmin
- How-To
date: 2022-11-10
description: Grafana and Prometheus are good monitoring tools. With the use of Docker, the deployment of these two gets way easier.
slug: deploy-grafana-and-prometheus-via-docker
tags:
- Docker
- Grafana
- Prometheus
title: Deploy Grafana and Prometheus via Docker
---

Tags: #Guide 
Categories: #Homelab #WorkInProgress 
LastEdited: 2022-03-28

---

## 1. Update the system
```shell
apt-get update && apt upgrade
```

## 2. Add a new user for Teamspeak
```shell
adduser --disabled-login teamspeak
```

---

## Credits
[**A comprehensive guide on deploying Teamspeak server on different OS's.**](https://www.hostinger.com/tutorials/how-to-make-a-teamspeak-3-server/#How_to_Make_a_TeamSpeak_3_Server_on_Ubuntu_1604)

[**Tables of default ports used by Teamspeak 3 server**](https://support.teamspeak.com/hc/en-us/articles/360002712257-Which-ports-does-the-TeamSpeak-3-server-use-)