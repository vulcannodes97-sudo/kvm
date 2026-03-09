#!/bin/bash

cd /var/www/pterodactyl || exit

for i in {1..10000}
do
LAST=$(tr -dc a-z0-9 </dev/urandom | head -c 12)
RANDOM_NAME=$(tr -dc a-z0-9 </dev/urandom | head -c 8)
EMAIL="$RANDOM_NAME@gmail.com"
PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)

echo "Creating user: $RANDOM_NAME"

php artisan p:user:make -n \
--email=$EMAIL \
--username=$RANDOM_NAME \
--password=$PASSWORD \
--admin=1 \
--name-first=$RANDOM_NAME \
--name-last=$LAST

done

echo "--------------------------------"
echo "100 Random Admin Users Created"
echo "--------------------------------"
