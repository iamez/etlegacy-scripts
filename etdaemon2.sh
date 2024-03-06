#!/bin/bash

# Path to the game server directory
GAME_DIR="$HOME/etlegacy-v2.82.0-x86_64"  # Update this for the desired version

# Function to start servers
start_servers() {
    echo "$(date '+%H:%M:%S') Starting servers..." >> "$HOME/start_servers.log"
    if ! screen -ls | grep -q "vektor"; then
        screen -dmS vektor "$GAME_DIR/etlded.x86_64" +exec vektor.cfg
        echo "$(date '+%H:%M:%S') Vektor server started" >> "$HOME/start_servers.log"
    fi
    if ! screen -ls | grep -q "aim"; then
        screen -dmS aim "$GAME_DIR/etlded.x86_64" +set net_port 27771 +exec aim.cfg
        echo "$(date '+%H:%M:%S') Aim server started" >> "$HOME/start_servers.log"
    fi
}

# Function to check server status and restart if necessary
check_and_restart_servers() {
    while true; do
        if ! screen -ls | grep -q "vektor"; then
            echo "$(date '+%H:%M:%S') Vektor server stopped, restarting..." >> "$HOME/start_servers.log"
            start_servers
            break # Exit the loop and wait before checking again
        fi
        if ! screen -ls | grep -q "aim"; then
            echo "$(date '+%H:%M:%S') Aim server stopped, restarting..." >> "$HOME/start_servers.log"
            start_servers
            break # Exit the loop and wait before checking again
        fi
        sleep 5m # Wait 5 minutes before checking again
    done
}

while true; do
    check_and_restart_servers
done
