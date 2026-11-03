#!/bin/bash

# Check if the editor port file exists
if [ ! -f .internal/editor.port ]; then
    echo "Error: .internal/editor.port not found."
    echo "Is the Defold editor running and the project open?"
    exit 1
fi

# Read the port
PORT=$(cat .internal/editor.port)
echo "Sending build command to Defold (Port: $PORT)..."

# Send build command
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "http://localhost:$PORT/command/build")

if [ "$RESPONSE" -eq 202 ]; then
    echo "Build command sent successfully."
else
    echo "Error sending build command. HTTP Status: $RESPONSE"
    exit 1
fi

# Ensure log file exists
touch log.txt

echo "Watching log.txt..."
echo "----------------------------------------"

# Wait a moment for log file to be ready
sleep 0.2

# Start tail in foreground with advanced coloring
# Use -F (follow with retry) to handle file recreation and -n 0 to start from end
# -F automatically retries if file is deleted/recreated
tail -F -n 0 log.txt 2>/dev/null | perl -ne '
BEGIN {
    $| = 1;
    $reset = "\e[0m";
    $bold = "\e[1m";

    # Define colors matching terminal output (from screenshot)
    %colors = (
        "ERROR:"   => "\e[0;31m", # Red
        "WARNING:" => "\e[0;33m", # Orange/Yellow (appears as orange)
        "WARN:"    => "\e[0;33m", # Orange/Yellow
        "DEBUG:"   => "\e[0;36m", # Cyan/Light Blue
        "INFO:"    => "\e[0m",    # White (default) - appears white on screenshot
        "TRACE:"   => "\e[90m", # Dark Gray (dim, subtle)
        "FATAL:"   => "\e[0;35m"  # Magenta
    );
}

# Match log levels at the start of line - color up to second colon (LEVEL: or LEVEL:CATEGORY:)
# Pattern: LEVEL: or LEVEL:CATEGORY:
if (/^((?:TRACE|DEBUG|INFO|WARNING|WARN|ERROR|FATAL):)([^:]*:?)(.*)$/i) {
    $lvl = uc($1);
    $category = $2;
    $rest = $3;

    # Get color for the level
    $col = $colors{$lvl};
    if (!$col) { $col = $reset; }

    # If category has second colon, include it in colored part
    if ($category =~ /^[^:]*:$/) {
        # Has second colon (like INFO:DLIB:)
        print "${col}${lvl}${category}${reset}${rest}\n";
    } else {
        # Only first colon (like INFO:   |)
        print "${col}${lvl}${reset}${category}${rest}\n";
    }
} else {
    # Regular line - print as is
    print $_;
}
'
