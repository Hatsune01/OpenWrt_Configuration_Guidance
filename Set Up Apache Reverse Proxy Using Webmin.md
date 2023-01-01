#Networking  

---

## 1. Create virtual host in Apache webserver

Fill the Specific address with the desired domain name.  
Set Port to 80.  
Fill the Server Name with the desired domain name.  
Keep other options as default.

## 2. Change virtual server options

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
Use the following command (if your connection to Webmin is already reverse proxied, NEVER stop Apache in Webmin! Otherwise you'll need the IP address of your server to connect to Webmin.

```bash
systemctl restart apache2
```

Now you should be able to connect to the host with the desired domain name.  

## PS
Below is an example directives file for a virtual host. If you use the Edit Directives module in Virtual Server Options, the VirtualHost tags will be hidden.

```apacheconf
<VirtualHost example.realbrandon.net:80>
    ServerName example.realbrandon.net

    ProxyPreserveHost On

    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
```

> When setting up reverse proxy using Apache for Webmin itself, don't add `ProxyPreserveHost On`. This directive will mess up the headers when Apache builds up the proxied request sent to Webmin.  
