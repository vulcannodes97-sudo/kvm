#!/bin/bash

while true
do
echo "=============================="
echo "      PTERODACTYL MENU"
echo "=============================="
echo "1. Show Nginx Server Name"
echo "2. Create Admin User"
echo "3. Clear History"
echo "4. Exit"
echo "=============================="

read -p "Select Option: " option

case $option in

1)
echo "Server Name:"
grep server_name /etc/nginx/sites-available/pterodactyl.conf
;;

2)
cd /var/www/pterodactyl || exit

PASSWORD=admin
USERNAME=admin

php artisan p:user:make -n \
--email=admin@gmail.com \
--username=${USERNAME} \
--password=$PASSWORD \
--admin=1 \
--name-first=raju \
--name-last=kumar

;;

3)
history -c
history -w
echo "History Cleared"
;;

4)
echo "Bye 👋"
exit
;;

*)
echo "Invalid Option"
;;

esac

echo ""
done
