#!/bin/bash

echo "====== Pterodactyl Admin Tool ======"

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Admin API Key: " API_KEY

echo ""
echo "Installing jq if needed..."
apt-get install jq -y >/dev/null 2>&1

echo "Creating new API key..."

RESPONSE=$(curl -s -X POST "$PANEL_URL/api/application/api-keys" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: Application/vnd.pterodactyl.v1+json" \
  -d '{
        "memo": "testing-key",
        "permissions": ["*"]
      }')

NEW_KEY=$(echo "$RESPONSE" | jq -r '.attributes.token')

echo "--------------------------------"
echo "New API Key:"
echo "$NEW_KEY"
echo "--------------------------------"

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
echo "All users are now ROOT ADMIN."
echo "Done."
echo "--------------------------------"
