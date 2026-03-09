#!/bin/bash

echo "===== Pterodactyl Role Editor ====="

# Panel URL auto detect (nginx)
DOMAIN=$(grep server_name /etc/nginx/sites-available/pterodactyl.conf | awk '{print $2}' | sed 's/;//')
PANEL_URL="https://$DOMAIN"

echo "Panel detected: $PANEL_URL"

read -p "Enter Application API Key: " API_KEY

# install jq if needed
apt-get install jq -y >/dev/null 2>&1

echo ""
echo "Fetching users..."
echo "--------------------------------"

curl -L -s "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -c '.data[]' | while read user
do

ID=$(echo "$user" | jq -r '.attributes.id')
USERNAME=$(echo "$user" | jq -r '.attributes.username')
EMAIL=$(echo "$user" | jq -r '.attributes.email')

echo "User: $USERNAME | $EMAIL"

# edit role → admin
curl -L -s -X PATCH "$PANEL_URL/api/application/users/$ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Role updated → admin=1"
echo "--------------------------------"

done

echo "All users role changed to ADMIN."
