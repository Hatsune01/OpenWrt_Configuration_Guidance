# This tutorial is for setting up Apache reverse proxy with Webmin and installing SSL certificates with Certbot.

# Setting Up Apache Reverse Proxy with Webmin

## 1. Create Virtual Host in Apache Webserver
Fill the Specific address with the desired domain name.  
Set Port to 80.  
Fill the Server Name with the desired domain name.  
Keep other options as default.

## 2. Change Virtual Server Options
Click the Aliases and Redirects module.  
Under Map local to remote URLs, set Local URL path to / and Remote URL to the ip address of the proxied host, such as http://localhost:3000/ (Don't forget the ending forward slash)  
Under Map remote Location: headers to local, do the same thing.  
Return to server index and click the Edit Directives module.  
Add the following line into the file:  

```
ProxyPreserveHost On
```

Save the directives file.  
Return to server index and Apply changes.  

## 3. Restart Apache 
Use the following command (if your connection to Webmin is already reverse proxied, NEVER stop Apache in Webmin! Or you'll lose your connection to Webmin, unless you go back to ip address):  

```
systemctl restart apache2
```

Now you should be able to connect to the host with the desired domain name.  

## PS
Below is an example directives file for a virtual host. If you use the Edit Directives module in Virtual Server Options, the VirtualHost tags will be hidden.

```
<VirtualHost example.realbrandon.net:80>
    ServerName example.realbrandon.net

    ProxyPreserveHost On

    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
```

On a side note, if you're setting up Apache Reverse Proxy for Webmin itself, don't add the ProxyPreserveHost On directive. This directive will mess up the headers when Apache builds up the proxied request sent to Webmin.  

# Installing SSL Certificates with Certbot

## 1. Install Certbot.
I'm doing it on Debian. If you're on other distros, please adjust your command for the package manager on your system.  
Also, I'm running the commands as root, and I'm doing it for my Apache server. If you're not running as root, add sudo to the start of every command. If you're using Nginx, change apache to nginx in every command.  

```
apt update
apt install certbot python-certbot-apache
```

## 2. Run Certbot.
```
certbot --apache -d example.realbrandon.net
```

Now you can enjoy https connections in all its glory.

## PS
This tutorial is written based on Jay's YouTube video. Loads of thanks to Jay. Have a check at his video if you're interested. Here is the link: https://youtu.be/WPPBO-QpiJ0