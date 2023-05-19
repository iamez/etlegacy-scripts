#!/bin/bash

# Set the path for the update log file
update_log_file="${CURRENT_USER:-$HOME}/legacyupdate/backup/logs/update.log"
backup_directory="${CURRENT_USER:-$HOME}/legacyupdate/backup"

# Check if necessary directories exist, create them if not
[ ! -d "$backup_directory/logs" ] && mkdir -p "$backup_directory/logs"
[ ! -d "$backup_directory" ] && mkdir -p "$backup_directory"
[ ! -f "$update_log_file" ] && touch "$update_log_file"

# Prompt the user to enter the update link, download and extract the update file
read -p "Enter the update link: " update_link && \
echo "Update link: $update_link" >> "$update_log_file" && \
cd "$backup_directory" >> "$update_log_file" && \
wget "$update_link" >> "$update_log_file" && \
update_file=$(find . -maxdepth 1 -type f -name "etlegacy-v*") && \
tar -zxvf "$update_file" >> "$update_log_file" && \
extracted_dir=$(find . -maxdepth 1 -type d -name "etlegacy-v*") >> "$update_log_file" && \
cd "$extracted_dir" >> "$update_log_file"

# Prompt the user to enter the command to terminate the running servers or use default value
read -p "Enter the command to terminate the running servers (default: 'screen -ls | grep -E \"(vektor|aim)\" | awk '{print \$1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit'): " server_termination_command
server_termination_command=${server_termination_command:-"screen -ls | grep -E \"(vektor|aim)\" | awk '{print \$1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit"}
eval "$server_termination_command" >> "$update_log_file"
sleep 3

# Prompt the user to enter the game root directory or use default value
read -p "Enter the game root directory (default: /home/et/etlegacy-v2.81.1-x86_64/): " game_directory
game_directory=${game_directory:-"/home/et/etlegacy-v2.81.1-x86_64/"}
read -p "Where is your /legacy/ folder (default: $game_directory/legacy/): " installation_file_path
installation_file_path=${installation_file_path:-"$game_directory/legacy/"}

# Search for older snapshots and move them to the backup directory
old_pk3_files=$(find "$installation_file_path" -name "legacy_v2.81.1-*.pk3" -print)
[ -n "$old_pk3_files" ] && { echo "Old legacy PK3 files:"; echo "$old_pk3_files"; mv $old_pk3_files "$backup_directory" >> "$update_log_file"; }

# Copy the contents of the update to the game directory
cp -r * "$game_directory"

# Save logs to legacyupdate directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully!" >> "$update_log_file"

# Remove the downloaded update file and extracted directory
cd "$backup_directory" >> "$update_log_file" && \
rm "$update_file" >> "$update_log_file" 2>&1 && \
rm -rf "$extracted_dir" >> "$update_log_file" 2>&1

# Print a message indicating the update was successful
echo "Update completed successfully!" >> "$update_log_file"
