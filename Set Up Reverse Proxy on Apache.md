---
categories:
- Sysadmin
- How-To
- Web Server
date: 2022-06-17
description: In this article, name-based reverse proxy with SSL on Apache is discussed .
slug: set-up-reverse-proxy-on-apache
tags:
- Apache
- Reverse Proxy
title: Set Up Reverse Proxy on Apache
---

Tags: #Guide 
Categories: #Sysadmin #WebHosting 
LastEdited: 2022-06-17

> Only 

---

## 1. Reverse proxy for applications with built-in web servers

This is way easier than reverse proxy for multiple sites. Two virtual hosts are needed. One for rewriting the HTTP links to HTTPS links. The other for reconstructing the URLs so that they point to the origin server.

```apacheconf
<VirtualHost *:80>

	ServerName grafana.brandonhan.net

	RewriteEngine on
	RewriteCond %{SERVER_NAME} =grafana.brandonhan.net
	RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
	# You can always refer to Certbot or Mozilla SSL generator for the Rewrite section.

</VirtualHost>

<VirtualHost *:443>

	ServerName grafana.brandonhan.net

	ProxyPreserveHost On
	ProxyPass / http://localhost:3000/
	# Include either the both trailing slashes for the two paths or neither of them. Otherwise, files may not be loaded correctly. Same for ProxyPassReverse.
	ProxyPassReverse / http://localhost:3000/

	SSLEngine on
	
```