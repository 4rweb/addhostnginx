# Nginx Host Creator (WordPress or php application)

## INSTALL
To install, simply download the script file and give it the executable permission.
```
curl -0 https://raw.githubusercontent.com/4rweb/addhostnginx/master/vhost/addhost.sh -o addhost.sh
chmod +x addhost.sh
```

## EXECUTE
```
sh addhost.sh
```

## HELP
read -p "Enter username : " username 
Put your linux ou machine name like ubuntu or root. In case of using wordpress use the user: www-data

read -p "Enter pathname : " path
path will be the name of the .conf files and the directory where the files are located

read -p "Enter domain name : " domain
domain like example.com (no need pass www) 

to add the www domain uncomment this field:
## with www: server_name $domain www.$domain

at the end of the file performs the checks and updates the nginx service

* The last command requires the installation of SSL, run only if you are installing certbot: But information on how to install cetboot here: https://certbot.eff.org/