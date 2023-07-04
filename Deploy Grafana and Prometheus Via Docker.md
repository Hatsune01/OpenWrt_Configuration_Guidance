---
categories:
- Sysadmin
- How-To
date: "2012-04-06"
description: spf13-vim is a cross platform distribution of vim plugins and resources for Vim.
slug: spf13-vim-3-0-release-and-new-website
tags:
- Docker
- Grafana
- Prometheus
title: Deploy Grafana and Prometheus via Docker
LastEdited: 2022-11-10
---

## 1. Install Docker
Just use the installer you made before.

## 2. Install Grafana

```bash
mkdir -p /data/grafana/storage
chmod 777 /data/grafana/storage
docker run -d -p 3000:3000 --name=grafana --restart=always -v /data/grafana/storage:/var/lib/grafana grafana/grafana
```

> Default username: admin  
> Default password: admin

## 3. Install node exporter on the MONITORED SERVER

> Remember to update the version number in your code if needed.

```bash
#!/bin/bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
tar xzvf node_exporter-1.4.0.linux-amd64.tar.gz
mv node_exporter-1.4.0.linux-amd64 /usr/local/bin/node_exporter

groupadd prometheus
useradd -g prometheus -m -d /var/lib/prometheus -s /sbin/nologin prometheus
mkdir /usr/local/prometheus
chown prometheus.prometheus -R /usr/local/prometheus

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=node_exporter-1.4.0
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/node_exporter/node_exporter --collector.processes --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($|/)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart node_exporter.service
systemctl enable node_exporter.service

systemctl start node_exporter.service
systemctl status node_exporter
```

## 4. Install Prometheus on the GRAFANA SERVER

```bash
mkdir -p /data/prometheus
chmod 777 /data/prometheus
vim prometheus.yml
```

```yaml
global:
  scrape_interval:     10s
  evaluation_interval: 10s

scrape_configs:
  - job_name: prometheus
	static_configs:
	  - targets: ['本机ip:9090']
		labels:
		  instance: prometheus
  - job_name: Monitoring
	static_configs:
	  - targets: ['被监控机器1ip:9100']
		labels:
		  instance: 名字1
	  - targets: ['被监控机器1ip:9100']
		labels:
		  instance: 名字2
	  - targets: ['被监控机器1ip:9100']
		labels:
		  instance: 名字3
```

```bash
docker run -d --restart=always --name=prometheus -p 9090:9090 -v /data/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus --storage.tsdb.retention.time=20d --config.file=/etc/prometheus/prometheus.yml --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles
```
*DO NOT put prom/prometheus behind those custom flags like storage.tsdb.retention.time. Doing so will run into an error, because those flags are not generic docker flags. Thus, specifying the docker image first!*

> Notice if prometheus.yml is changed, the container should be restarted.
```bash
docker restart {Prometheus container id}
```

---

## Credits
[**Chris’ blog on how to install Grafana and Prometheus using Docker**](https://blog.chriswang.work/archives/Grafana-Prometheus.html)
