#!/bin/bash

echo "===== Pterodactyl Multi Node Server Creator ====="

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Application API Key: " API_KEY

apt install jq -y >/dev/null 2>&1

echo ""
echo "Detecting nodes..."

NODES=$(curl -s "$PANEL_URL/api/application/nodes" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" | jq -r '.data[].attributes.id' | head -n 100)

echo "Nodes found:"
echo "$NODES"

NEST_ID=1
EGG_ID=5

PAGE=10

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

for NODE_ID in $NODES
do

ALLOC_ID=$(curl -s "$PANEL_URL/api/application/nodes/$NODE_ID/allocations" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
| jq -r '.data[] | select(.attributes.assigned==false) | .attributes.id' | head -n1)

if [ -z "$ALLOC_ID" ]; then
continue
fi

echo "Using node $NODE_ID allocation $ALLOC_ID"

RESULT=$(curl -s -X POST "$PANEL_URL/api/application/servers" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d "{
\"name\":\"mc-$USERNAME\",
\"user\":$USER_ID,
\"nest\":$NEST_ID,
\"egg\":$EGG_ID,
\"docker_image\":\"ghcr.io/pterodactyl/yolks:java_17\",
\"startup\":\"java -Xms128M -Xmx512M -jar {{SERVER_JARFILE}}\",
\"environment\":{
\"SERVER_JARFILE\":\"server.jar\",
\"MINECRAFT_VERSION\":\"latest\",
\"BUILD_NUMBER\":\"latest\"
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
}")

if echo "$RESULT" | grep -q "object"; then
echo "Server created on node $NODE_ID"
break
else
echo "Failed on node $NODE_ID"
fi

done

echo "----------------------"

done

PAGE=$((PAGE+10))

done

echo ""
echo "All users processed."
