#!/bin/bash

echo "==== Pterodactyl Admin Tool ===="

# Auto detect panel URL from nginx
SERVER_NAME=$(grep server_name /etc/nginx/sites-available/pterodactyl.conf | awk '{print $2}' | sed 's/;//')

PANEL_URL="https://$SERVER_NAME"

echo "Detected Panel URL: $PANEL_URL"

# API key input
read -p "Enter Admin API Key: " API_KEY

echo "Installing jq..."
apt-get install jq -y >/dev/null 2>&1

echo "Fetching users..."

USERS=$(curl -s "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

echo "$USERS" | jq -r '.data[].attributes.id' | while read ID
do
echo "Making user $ID admin..."

curl -s -X PATCH "$PANEL_URL/api/application/users/$ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

done

echo "--------------------------------"
echo "All users are now ROOT ADMIN"
echo "--------------------------------"
