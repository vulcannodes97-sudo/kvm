#!/bin/bash

echo "===== Pterodactyl API Manager ====="

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Application API Key: " API_KEY

echo ""
echo "Testing API..."

TEST=$(curl -s -L "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

if echo "$TEST" | grep -q "errors"; then
echo "API ERROR:"
echo "$TEST"
exit
fi

echo "API OK"
echo ""

echo "$TEST" | jq -c '.data[]' | while read user
do

USER_ID=$(echo "$user" | jq -r '.attributes.id')
USERNAME=$(echo "$user" | jq -r '.attributes.username')

echo "User: $USERNAME (ID:$USER_ID)"

curl -s -L -X PATCH "$PANEL_URL/api/application/users/$USER_ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Admin enabled"

done

echo ""
echo "Finished."
