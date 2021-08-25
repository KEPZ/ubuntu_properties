#!/usr/bin/env bash
#set -xe #For debugging purposes

#The $EUID environment variable holds the current users's UID. Root's UID is 0. Or use id -u.
if [ "$EUID" -ne 0 ] 
	then echo "Notice: Please run this script as root"
	exit 1
fi

#Set timezone
TZ='Europe/Moscow'
echo $TZ > /etc/timezone

apt install -y tzdata
rm -f /etc/localtime

#Reconfigure in noninteractive mode
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && apt clean

if [ $? -eq 0 ]; then
	echo -e "Set Timezone=$TZ - \033[32mOK\033[0m"
else
	echo "Set Timezone=$TZ - ERROR"
fi

#Set LANG=RU in /etc/default/locale
update-locale LANG=ru_RU.UTF-8 2>/dev/null
#grep -q for quiet/silent mode (no output) with exit code 0 if no errors
grep -q "LANG=ru_RU.UTF-8" /etc/default/locale && echo -e "Set LANG=ru_RU.UTF-8 - \033[32mOK\033[0m" || echo "Set LANG=ru_RU.UTF-8 - ERROR"

#SSH server configuration
sed -i "s/^#*Port 22/Port 3322/" /etc/ssh/sshd_config
sed -i "s/^#*PermitRootLogin .*/PermitRootLogin No/g" /etc/ssh/sshd_config
systemctl restart sshd.service

#Add new user and set him passwd
username=support
if getent passwd $username > /dev/null 2>&1; then
	echo "The user '$username' exists. Please delete it or change username in the script."
	exit 1
else
	useradd -m -d /home/support -s /bin/bash -c "Support User" $username && echo -e "Add new user '$username' - \033[32mOK\033[0m"
	echo 'support:pass123' | chpasswd
fi

#Allow user to start/stop/restart services as sudo without password
echo "Cmnd_Alias USER_SERVICES = /bin/systemctl start *,/bin/systemctl stop *,/bin/systemctl restart *,/bin/systemctl status *
support ALL=(ALL) NOPASSWD:USER_SERVICES" > /etc/sudoers.d/support

#Deploy nginx server
apt install nginx -y
systemctl enable nginx
systemctl restart nginx

#Deploy Monit server
apt install monit -y
systemctl enable monit

#Configure monit
echo "set httpd port 2812 and
allow localhost
allow md5 /etc/monit/.htpasswd monit" > /etc/monit/conf.d/default.conf
systemctl restart monit


#Set Nginx to proxy requests to the Monit server with the basic auth using monit/tinom credentials
apt install apache2-utils -y
htpasswd -b -c /etc/monit/.htpasswd monit tinom

rm -rf /etc/nginx/sites-enabled/*

echo "server {
listen 999;
location /monit/ {
rewrite ^/monit/(.*) /$1 break;
proxy_ignore_client_abort on;
proxy_pass http://127.0.0.1:2812;
}
}" > /etc/nginx/conf.d/monit.conf

systemctl reload nginx 

ps -C nginx >/dev/null && echo "NGINX is Running" || echo "NGINX is Not running"
ps -C monit >/dev/null && echo "MONIT is Running" || echo "MONIT is Not running"
ps -C sshd >/dev/null && echo "SSHD is Running" || echo "SSHD is Not running"

echo "Task finished. Check http://domain_name:999/monit (login: monit, pass: tinom)"
