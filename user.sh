#!/bin/bash

cd /var/www/pterodactyl || exit

TOTAL=10000
BATCH=20
LAST=$(tr -dc a-z0-9 </dev/urandom | head -c 6)
create_user() {

NAME=$(tr -dc a-z0-9 </dev/urandom | head -c 8)
EMAIL="$NAME@gmail.com"
PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)

php artisan p:user:make -n \
--email=$EMAIL \
--username=$NAME \
--password=$PASS \
--admin=1 \
--name-first=$NAME \
--name-last=$LAST >/dev/null 2>&1

echo "Created: $NAME"

}

export -f create_user

for ((i=1;i<=TOTAL;i++))
do
create_user &

if (( i % BATCH == 0 ))
then
wait
fi

done

wait

echo "--------------------------------"
echo "$TOTAL Users Created Fast"
echo "--------------------------------"
