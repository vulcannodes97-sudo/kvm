#!/bin/bash

echo "===== Pterodactyl Auto Server Creator ====="

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Application API Key: " API_KEY

NODE_ID=2
NEST_ID=1
EGG_ID=5

apt install jq -y >/dev/null 2>&1

PAGE=1

while true
do

RESPONSE=$(curl -s "$PANEL_URL/api/application/users?page=$PAGE" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

COUNT=$(echo "$RESPONSE" | jq '.data | length')

[ "$COUNT" = "0" ] && break

echo "$RESPONSE" | jq -c '.data[]' | while read user
do

USER_ID=$(echo "$user" | jq -r '.attributes.id')
USERNAME=$(echo "$user" | jq -r '.attributes.username')

echo ""
echo "User: $USERNAME"

curl -s -X PATCH "$PANEL_URL/api/application/users/$USER_ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Admin enabled"

for i in {1..10}
do

ALLOC_ID=$(curl -s "$PANEL_URL/api/application/nodes/$NODE_ID/allocations" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
| jq -r '.data[] | select(.attributes.assigned==false) | .attributes.id' | head -n1)

echo "Creating server $i..."

curl -s -X POST "$PANEL_URL/api/application/servers" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d "{
\"name\":\"mc-$USERNAME-$i\",
\"user\":$USER_ID,
\"nest\":$NEST_ID,
\"egg\":$EGG_ID,
\"docker_image\":\"ghcr.io/pterodactyl/yolks:java_17\",
\"startup\":\"java -Xms128M -Xmx512M -jar server.jar\",
\"environment\":{
\"SERVER_JARFILE\":\"server.jar\",
\"MINECRAFT_VERSION\":\"latest\"
},
\"limits\":{
\"memory\":0,
\"swap\":0,
\"disk\":0,
\"io\":500,
\"cpu\":0
},
\"feature_limits\":{
\"databases\":0,
\"allocations\":1,
\"backups\":0
},
\"allocation\":{
\"default\":$ALLOC_ID
}
}" >/dev/null

echo "Server $i created"

done

echo "----------------------"

done

PAGE=$((PAGE+1))

done

echo ""
echo "All users processed."
