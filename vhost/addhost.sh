#!/usr/bin/env bash
#
# Nginx - new server block 

read -p "Enter username : " username
read -p "Enter pathname : " path
read -p "Enter domain name : " domain

ok() { echo -e '\e[32m'$domain'\e[m'; } # Green
die() { echo -e '\e[1;31m'$domain'\e[m'; exit 1; }

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/usr/share/nginx/sites'
WEB_USER=$username

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
#[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$path <<EOF


server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    ## with www: server_name $domain www.$domain

    root $WEB_DIR/$path/www;
    index index.php index.html index.htm index.nginx-debian.html;

    #access_log $WEB_DIR/$path/logs/$path-access.log;
    access_log off;

    error_log $WEB_DIR/$path/logs/$path-error.log;
    #error_log off;

    location / {
      ##try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
      try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    error_page 404 /errors/404.html;
    error_page 500 502 503 504 /errors/50x.html;

    location = /50x.html {
      root /usr/share/nginx/sites/$path/www/errors;
    }

    location ~ \.php$ {
      #try_files \$uri =404;

      fastcgi_pass unix:/run/php/php7.4-fpm.sock;

      include fastcgi_params;
      fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
      fastcgi_split_path_info ^(.+\.php)(/.+)\$;

      include snippets/fastcgi-php.conf;
      fastcgi_no_cache \$no_cache;
    }

    ##
    # FastCGI cache exceptions
    ##

    set \$no_cache   0;
    set \$cache_uri  \$request_uri;

    if (\$request_method = POST) {
        set \$cache_uri  "null cache";
        set \$no_cache   1;
    }

    if (\$query_string != "") {
        set \$cache_uri  "null cache";
        set \$no_cache   1;
    }

    if (\$request_uri ~* "(/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(_index)?.xml|[a-z0-9_-]+-sitemap([0-9]+)?.xml)") {
        set \$cache_uri  "null cache";
        set \$no_cache   1;
    }

    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in") {
        set \$cache_uri  "null cache";
        set \$no_cache   1;
    }

    #enable gzip compression
    gzip on;
    gzip_static on;
    gzip_vary on;
    gzip_disable "msie6";
    gzip_types text/css text/x-component application/x-javascript application/javascript text/javascript text/x-js text/richtext image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
    gzip_http_version 1.1;
    gzip_comp_level 6;
    gzip_proxied any;

    ##
    # Browser cache config
    ##

    location ~ \.(css|htc|js|js2|js3|js4)$ {
       expires max;
       add_header Pragma "public";
       add_header Cache-Control "max-age=31536000, public, must-revalidate, proxy-revalidate";
    }

    location ~ \.(html|htm|rtf|rtx|svg|svgz|txt|xsd|xsl|xml)$ {
       expires 3600s;
       add_header Pragma "public";
       add_header Cache-Control "max-age=3600, public, must-revalidate, proxy-revalidate";
    }

    location ~ \.(asf|asx|wax|wmv|wmx|avi|bmp|class|divx|doc|docx|eot|exe|gif|gz|gzip|ico|jpg|jpeg|jpe|json|mdb|mid|midi|mov|qt|mp3|m4a|mp4|m4v|mpeg|mpg|mpe|mpp|otf|odb|odc|odf|odg|odp|ods|odt|ogg|pdf|png|pot|pps|ppt|pptx|ra|ram|svg|svgz|swf|tar|tif|tiff|ttf|ttc|wav|wma|wri|xla|xls|xlsx|xlt|xlw|zip)$ {
       expires max;
       add_header Pragma "public";
       add_header Cache-Control "max-age=31536000, public, must-revalidate, proxy-revalidate";
       log_not_found off;
    }

    ##
    # robots.txt
    ##

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    ##
    # Deny access to hidden files
    ##

    location ~ /\. {
      deny all;
    }

    ##
    # Deny access to uploaded PHP files
    ##

    location ~* /(?:uploads|files)/.*\.php$ {
      deny all;
    }

    ##
    # Deny access to WordPress include-only files
    ##

    location ~ ^/wp-admin/includes/ {
        deny all;
    }
    location ~ ^/wp-includes/[^/]+\.php$ {
        deny all;
    }
    location ~ ^/wp-includes/js/tinymce/langs/.+\.php {
        deny all;
    }
    location ~ ^/wp-includes/theme-compat/ {
        deny all;
    }

}
EOF

# Creating {public,log and copy errors directories} directories
mkdir -p $WEB_DIR/$path/www
mkdir -p $WEB_DIR/$path/logs

## create erro pages before run this
## cp -r $WEB_DIR/errors $WEB_DIR/$path/www/

# Creating index.html file
cat > $WEB_DIR/$path/www/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
      	<title>$domain</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$domain<h1></header>
        <div id="wrapper"><p>Hello World</p></div>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Changing permissions // ubuntu:ubuntu
sudo chown -R $WEB_USER:$WEB_USER $WEB_DIR/$path

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$path $NGINX_ENABLED_VHOSTS/$path

# Restart
while true; do
    read -p "Do you wish test nginx? " yn
    case $yn in
        [Yy]* ) sudo nginx -t; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "nginx is ok? " yn
    case $yn in
        [Yy]* ) sudo systemctl reload nginx; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Install SSL? " yn
    case $yn in
        [Yy]* ) sudo certbot --nginx; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

ok "SSL Created for $domain"
