#!/bin/bash

echo "Pterodactyl EULA Fix + Start Automation"

read -p "Panel URL (e.g. https://panel.example.com): " PANEL_URL
read -p "Application API Key: " API_KEY

VOLUME_BASE="/var/lib/pterodactyl/volumes"

apt install jq -y >/dev/null 2>&1

PAGE=1

while true; do

RESPONSE=$(curl -s "$PANEL_URL/api/application/servers?page=$PAGE" \
 -H "Authorization: Bearer $API_KEY" \
 -H "Accept: Application/vnd.pterodactyl.v1+json")

COUNT=$(echo "$RESPONSE" | jq '.data | length')

[ "$COUNT" = "0" ] && break

echo "$RESPONSE" | jq -c '.data[]' | while read server
do

UUID=$(echo "$server" | jq -r '.attributes.uuid')
UUID_SHORT=$(echo "$server" | jq -r '.attributes.uuidShort')
NAME=$(echo "$server" | jq -r '.attributes.name')

DIR="$VOLUME_BASE/$UUID"

# fallback if full uuid folder not found
if [ ! -d "$DIR" ]; then
DIR="$VOLUME_BASE/$UUID_SHORT"
fi

echo ""
echo "Server: $NAME"
echo "UUID: $UUID_SHORT"
echo "Path: $DIR"

if [ -d "$DIR" ]; then

echo "Writing eula.txt..."
echo "eula=true" > "$DIR/eula.txt"

echo "Starting server..."

RESULT=$(curl -s -X POST "$PANEL_URL/api/client/servers/$UUID_SHORT/power" \
 -H "Authorization: Bearer $API_KEY" \
 -H "Content-Type: application/json" \
 -d '{"signal":"start"}')

echo "Start signal sent"

else

echo "Server folder not found on this node"

fi

echo "----------------------------"

done

PAGE=$((PAGE+1))

done

echo ""
echo "Finished processing all servers."
