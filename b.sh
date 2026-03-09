#!/bin/bash

echo "===== Pterodactyl User Admin Editor ====="

# Auto detect panel domain from nginx
DOMAIN=$(grep server_name /etc/nginx/sites-available/pterodactyl.conf | awk '{print $2}' | sed 's/;//')
PANEL_URL="https://$DOMAIN"

echo "Detected Panel URL: $PANEL_URL"

# API key
read -p "Enter Application API Key: " API_KEY

# install jq if missing
apt install jq -y >/dev/null 2>&1

echo ""
echo "Fetching users..."
echo ""

curl -s "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -c '.data[]' | while read user
do

ID=$(echo $user | jq -r '.attributes.id')
USERNAME=$(echo $user | jq -r '.attributes.username')
EMAIL=$(echo $user | jq -r '.attributes.email')

echo "User Found → $USERNAME ($EMAIL)"

echo "Making admin..."

curl -s -X PATCH "$PANEL_URL/api/application/users/$ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Admin Enabled"
echo "---------------------------"

done

echo "All users processed."
