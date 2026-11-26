#!/bin/bash

adb reverse tcp:8000 tcp:8000

echo "Forwarded port"
echo ""

echo "Attempting to start server"
echo ""

python3 -m http.server 8000 --bind 127.0.0.1

echo ""
echo "If no error, then server is online"
echo ""

read -p "Press ENTER to stop server/close this window.."
