#!/bin/bash

# Check if the editor port file exists
if [ ! -f .internal/editor.port ]; then
    echo "Error: .internal/editor.port not found."
    echo "Is the Defold editor running and the project open?"
    exit 1
fi

# Read the port
PORT=$(cat .internal/editor.port)
echo "Sending hot-reload command to Defold (Port: $PORT)..."

# Send hot-reload command
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "http://localhost:$PORT/command/hot-reload")

if [ "$RESPONSE" -eq 202 ]; then
    echo "Hot-reload command sent successfully."
else
    echo "Error sending hot-reload command. HTTP Status: $RESPONSE"
    exit 1
fi

