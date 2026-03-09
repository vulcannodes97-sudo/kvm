#!/bin/bash

echo "===== Pterodactyl Auto Manager ====="

cd /var/www/pterodactyl || exit

echo "Detecting configuration..."

NODE_ID=$(php artisan tinker --execute="echo DB::table('nodes')->value('id');")
EGG_ID=$(php artisan tinker --execute="echo DB::table('eggs')->value('id');")
NEST_ID=$(php artisan tinker --execute="echo DB::table('nests')->value('id');")

echo "Node: $NODE_ID"
echo "Nest: $NEST_ID"
echo "Egg: $EGG_ID"

echo ""
echo "Setting all users → admin..."

php artisan tinker --execute="DB::table('users')->update(['root_admin' => 1]);"

echo "Done."
echo ""

echo "Fetching users..."

USER_LIST=$(php artisan tinker --execute="DB::table('users')->pluck('id');")

echo "$USER_LIST" | grep -o '[0-9]\+' | while read USER_ID
do

USERNAME=$(php artisan tinker --execute="echo DB::table('users')->where('id',$USER_ID)->value('username');")

echo "User: $USERNAME (ID:$USER_ID)"

for i in {1..10}
do

ALLOC_ID=$(php artisan tinker --execute="echo DB::table('allocations')->whereNull('server_id')->value('id');")

if [ -z "$ALLOC_ID" ]; then
echo "No free allocations left!"
break
fi

php artisan p:server:create \
--name="auto-$USERNAME-$i" \
--user=$USER_ID \
--egg=$EGG_ID \
--nest=$NEST_ID \
--node=$NODE_ID \
--allocation=$ALLOC_ID \
--memory=0 \
--disk=0 \
--cpu=0 >/dev/null

echo "Server $i created (allocation $ALLOC_ID)"

done

echo "-----------------------------"

done

echo "All users processed."
