#!/bin/bash

echo "Pterodactyl User Admin Editor"

cd /var/www/pterodactyl || exit

echo "Current users:"
php artisan tinker --execute="DB::table('users')->select('id','username','email','root_admin')->get();"

echo ""
echo "Setting all users → admin..."

php artisan tinker --execute="DB::table('users')->update(['root_admin' => 1]);"

echo ""
echo "Done. All users are now admin."
