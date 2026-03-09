#!/bin/bash

cd /var/www/pterodactyl || exit

# auto detect panel domain from nginx
DOMAIN=$(grep server_name /etc/nginx/sites-available/pterodactyl.conf | awk '{print $2}' | sed 's/;//')

PANEL_URL="https://$DOMAIN"

# read API key
read -p "Enter Application API Key: " API_KEY

echo "Panel detected: $PANEL_URL"

apt install jq -y >/dev/null 2>&1

echo "Fetching users..."

USERS=$(curl -s "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

echo "$USERS" | jq -r '.data[].attributes.id' | while read ID
do
echo "Setting admin for user ID $ID"

curl -s -X PATCH "$PANEL_URL/api/application/users/$ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

done

echo "--------------------------------"
echo "All users are now ADMIN"
echo "--------------------------------"
