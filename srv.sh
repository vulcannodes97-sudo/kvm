#!/bin/bash

echo "===== Pterodactyl Auto Manager ====="

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Application API Key: " API_KEY

echo ""
echo "Installing jq if needed..."
apt install jq -y >/dev/null 2>&1

echo ""
echo "Detecting node..."

NODE_ID=$(curl -s -L "$PANEL_URL/api/application/nodes" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -r '.data[0].attributes.id')

echo "Node detected: $NODE_ID"

echo ""
echo "Detecting egg..."

EGG_ID=$(curl -s -L "$PANEL_URL/api/application/nests" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -r '.data[0].attributes.relationships.eggs.data[0].attributes.id')

echo "Egg detected: $EGG_ID"

PAGE=1

while true
do

RESPONSE=$(curl -s -L "$PANEL_URL/api/application/users?page=$PAGE" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

COUNT=$(echo "$RESPONSE" | jq '.data | length')

if [ "$COUNT" = "0" ] || [ "$COUNT" = "null" ]; then
break
fi

echo ""
echo "Processing users page $PAGE..."

echo "$RESPONSE" | jq -c '.data[]' | while read user
do

USER_ID=$(echo "$user" | jq -r '.attributes.id')
USERNAME=$(echo "$user" | jq -r '.attributes.username')

echo "User: $USERNAME (ID:$USER_ID)"

echo "Setting admin..."

curl -s -L -X PATCH "$PANEL_URL/api/application/users/$USER_ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Admin enabled"

for i in {1..10}
do

ALLOC_ID=$(curl -s -L "$PANEL_URL/api/application/nodes/$NODE_ID/allocations" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -r '.data[] | select(.attributes.assigned==false) | .attributes.id' | head -n 1)

if [ -z "$ALLOC_ID" ]; then
echo "No free allocation!"
break
fi

echo "Creating server $i..."

curl -s -L -X POST "$PANEL_URL/api/application/servers" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d "{
\"name\": \"auto-$USERNAME-$i\",
\"user\": $USER_ID,
\"egg\": $EGG_ID,
\"docker_image\": \"ghcr.io/pterodactyl/yolks:nodejs_18\",
\"startup\": \"npm start\",
\"environment\": {},
\"limits\": {
\"memory\": 0,
\"swap\": 0,
\"disk\": 0,
\"io\": 500,
\"cpu\": 0
},
\"feature_limits\": {
\"databases\": 0,
\"allocations\": 1,
\"backups\": 0
},
\"allocation\": {
\"default\": $ALLOC_ID
}
}" >/dev/null

echo "Server $i created"

done

echo "---------------------------"

done

PAGE=$((PAGE+1))

done

echo ""
echo "All users processed."
