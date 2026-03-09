#!/bin/bash

echo "===== Pterodactyl API Auto Manager ====="

read -p "Enter Panel URL: " PANEL_URL
read -p "Enter Application API Key: " API_KEY

echo ""
echo "Testing API connection..."

API_TEST=$(curl -s -L "$PANEL_URL/api/application/users" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json")

if echo "$API_TEST" | grep -q "errors"; then
echo "API ERROR:"
echo "$API_TEST"
exit 1
fi

echo "API connection successful."
echo ""

echo "Fetching users..."

echo "$API_TEST" | jq -c '.data[]' | while read user
do

USER_ID=$(echo "$user" | jq -r '.attributes.id')
USERNAME=$(echo "$user" | jq -r '.attributes.username')
EMAIL=$(echo "$user" | jq -r '.attributes.email')

echo ""
echo "User: $USERNAME ($EMAIL)"

echo "Setting admin..."

curl -s -L -X PATCH "$PANEL_URL/api/application/users/$USER_ID" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d '{"root_admin": true}' >/dev/null

echo "Admin enabled"

for i in {1..10}
do

echo "Creating server $i..."

curl -s -L -X POST "$PANEL_URL/api/application/servers" \
-H "Authorization: Bearer $API_KEY" \
-H "Content-Type: application/json" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-d "{
\"name\": \"auto-$USERNAME-$i\",
\"user\": $USER_ID,
\"egg\": 1,
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
\"default\": 1
}
}" >/dev/null

echo "Server $i created"

done

echo "--------------------------"

done

echo ""
echo "All users processed."
