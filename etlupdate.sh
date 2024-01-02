#!/bin/bash

# Function for handling errors
handle_error() {
  echo "Error: $1"
  exit 1
}

# Function for logging messages to the update log
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$update_log_file"
}

# Set the path for the update log file
update_log_file="${CURRENT_USER:-$HOME}/legacyupdate/backup/logs/update_$(date).log"
backup_directory="${CURRENT_USER:-$HOME}/legacyupdate/backup"
default_server_termination_command="screen -ls | grep -E '(vektor|aim)' | awk '{print \$1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit"
default_game_directory="/home/et/etlegacy-v2.81.1-x86_64"
default_installation_file_path="${default_game_directory}/legacy/"

# Check if necessary directories exist, create them if not
[ ! -d "$backup_directory/logs" ] && mkdir -p "$backup_directory/logs"
[ ! -d "$backup_directory" ] && mkdir -p "$backup_directory"
[ ! -f "$update_log_file" ] && touch "$update_log_file"

# Create a new log file
log_message "Starting update process..."

# Prompt the user to enter the update link, download and extract the update file
read -p "Enter the update link: " update_link && \
log_message "Update link: $update_link" && \
cd "$backup_directory" && \
wget "$update_link" && \
update_file=$(find . -maxdepth 1 -type f -name "etlegacy-v*") && \
tar -zxvf "$update_file" >> "$update_log_file" 2>&1 && \
extracted_dir=$(find . -maxdepth 1 -type d -name "etlegacy-v*") && \
cd "$extracted_dir"

# Terminate running servers
server_termination_command=${default_server_termination_command}
eval "$server_termination_command"
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

  # Append old_pk3_files information to the main update log file
  echo "Old legacy PK3 files:" >> "$update_log_file"
  echo "$old_pk3_files" >> "$update_log_file"

  # Move old_pk3_files to backup directory
  mv $old_pk3_files "$backup_directory" >> "$update_log_file"
fi

# Copy the contents of the update to the game directory
cp -r * "$game_directory"

# Search for new snapshots
new_pk3_files=$(find "$game_directory" -name "legacy_v2.81.1-*.pk3" -print)

# Print a message indicating the update was successful
if [ -n "$new_pk3_files" ]; then
  log_message "Update completed successfully!"

  # Get the updated version from the first file in the list
  updated_version=$(echo "${new_pk3_files%%$'\n'*}" | awk -F'legacy_v2.81.1-' '{print $2}' | cut -d'.' -f1-3)

  log_message "Updated to version: $updated_version"
  echo "Updated to version: $updated_version from $old_pk3_files " >> "$update_log_file"

  # Copy new_pk3_files to Apache server directory
  for file in $new_pk3_files; do
    if [ -e "$file" ]; then
      cp "$file" "/var/www/html/legacy/"
    fi
  done
else
  log_message "No update was performed."
fi

# Save logs to legacyupdate directory
log_message "Update process finished."
log_message "------------------------------------"

# Remove the downloaded update file and extracted directory
cd "$backup_directory" && \
rm "$update_file" >> "$update_log_file" 2>&1 || handle_error "Failed to remove the downloaded update file."
rm -rf "$extracted_dir" >> "$update_log_file" 2>&1 || handle_error "Failed to remove the extracted directory."

