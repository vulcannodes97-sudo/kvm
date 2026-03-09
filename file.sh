#!/bin/bash

echo "Pterodactyl Batch Automation"

read -p "Panel URL: " PANEL_URL
read -p "Application API Key: " API_KEY

apt install jq -y >/dev/null 2>&1

echo ""
echo "Fetching servers..."

SERVERS=$(curl -s "$PANEL_URL/api/application/servers" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

echo "$SERVERS" | jq -c '.data[]' | while read server
do

UUID=$(echo "$server" | jq -r '.attributes.uuid')
NAME=$(echo "$server" | jq -r '.attributes.name')

echo ""
echo "Server: $NAME"

DIR="/var/lib/pterodactyl/volumes/$UUID"

if [ -d "$DIR" ]; then

echo "Creating eula.txt..."

echo "eula=true" > "$DIR/eula.txt"

echo "Starting server..."

curl -s -X POST "$PANEL_URL/api/client/servers/$UUID/power" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-d '{"signal":"start"}' >/dev/null

echo "Server started"

else

echo "Server directory not found"

fi

echo "-------------------------"

done

echo ""
echo "All servers processed."
