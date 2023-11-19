#!/bin/bash

# Set the path for the update log file
update_log_file="${CURRENT_USER:-$HOME}/legacyupdate/backup/logs/update.log"
backup_directory="${CURRENT_USER:-$HOME}/legacyupdate/backup"
default_server_termination_command="screen -ls | grep -E '(vektor|aim)' | awk '{print \$1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit"
default_game_directory="/home/et/etlegacy-v2.81.1-x86_64"
default_installation_file_path="${default_game_directory}/legacy/"

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

# Terminate running servers
server_termination_command=${default_server_termination_command}
eval "$server_termination_command" >> "$update_log_file"
sleep 3

# Prompt the user to enter the game directory
read -p "Enter the game root directory (default: '${default_game_directory}'): " game_directory
game_directory=${game_directory:-"${default_game_directory}"}

# Prompt the user to enter the installation file path
read -p "Where is your /legacy/ folder (default: '${default_installation_file_path}'): " installation_file_path
installation_file_path=${installation_file_path:-"${default_installation_file_path}"}

# Search for older snapshots and move them to the backup directory
old_pk3_files=$(find "$installation_file_path" -name "legacy_v2.81.1-*.pk3" -print)
if [ -n "$old_pk3_files" ]; then
  echo "Old legacy PK3 files:"
  echo "$old_pk3_files"
  mv $old_pk3_files "$backup_directory" >> "$update_log_file"
fi

# Copy the contents of the update to the game directory
cp -r * "$game_directory"

# Search for new snapshots
new_pk3_files=$(find "$game_directory" -name "legacy_v2.81.1-*.pk3" -print)

# Print a message indicating the update was successful
if [ -n "$new_pk3_files" ]; then
  echo "Update completed successfully!"
  echo "Updated from version ${old_pk3_files##*/} to ${new_pk3_files##*/}"
  echo "Update from ${old_pk3_files##*/} to ${new_pk3_files##*/}" >> "$update_log_file"

  # Copy new_pk3_files to Apache server directory
  for file in $new_pk3_files; do
    if [ -e "$file" ]; then
      sudo cp "$file" "/var/www/html/legacy/"
      sudo chown fastdl:fastdl "/var/www/html/legacy/${file##*/}"
    fi
  done
else
  echo "No update was performed."
fi

# Save logs to legacyupdate directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully!" >> "$update_log_file"

# Remove the downloaded update file and extracted directory
cd "$backup_directory" >> "$update_log_file" && \
rm "$update_file" >> "$update_log_file" 2>&1 && \
rm -rf "$extracted_dir" >> "$update_log_file" 2>&1
