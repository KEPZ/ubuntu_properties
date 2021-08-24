#!/usr/bin/env bash
#set -xe #For debugging purposes

#The $EUID environment variable holds the current users's UID. Root's UID is 0. Or use id -u.
if [ "$EUID" -ne 0 ] 
	then echo "Notice: Please run this script as root"
	exit
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
grep -q "LANG=ru_RU.UTF-8" /etc/default/locale  && echo -e "Set LANG=ru_RU.UTF-8 - \033[32mOK\033[0m" || echo "Set LANG=ru_RU.UTF-8 - ERROR"

#SSH server configuration
sed -i "s/^#*Port 22/Port 3322/" /etc/ssh/sshd_config
sed -i "s/^#*PermitRootLogin .*/PermitRootLogin No/g" /etc/ssh/sshd_config
systemctl restart sshd.service

#Add new user and set him passwd
username=support
if getent passwd $username > /dev/null 2>&1; then
	echo "The user '$username' exists. ERROR and EXIT"
	exit
else
	useradd -m -d /home/support -s /bin/bash -c "Support User" $username && echo -e "Add new user '$username' - \033[32mOK\033[0m"
	echo 'support:pass123' | chpasswd
fi

#Allow to start/stop/restart services as sudo without password
echo 'Cmnd_Alias USER_SERVICES = /bin/systemctl start *,/bin/systemctl stop *,/bin/systemctl restart *,/bin/systemctl status *' >> /etc/sudoers
echo 'support ALL=(ALL) NOPASSWD:USER_SERVICES' >> /etc/sudoers
