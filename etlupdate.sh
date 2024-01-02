#!/bin/bash

handle_error() {
  echo "Error: $1"
  exit 1
}


log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$update_log_file"
}


download_and_extract_update() {
  cd "$backup_directory" || handle_error "Failed to change directory to $backup_directory"
  wget "$update_link" || handle_error "Failed to download the update file"
  update_file=$(find . -maxdepth 1 -type f -name "etlegacy-v*")
  tar -zxvf "$update_file" >> "$update_log_file" 2>&1 || handle_error "Failed to extract the update file"
  extracted_dir=$(find . -maxdepth 1 -type d -name "etlegacy-v*")
  cd "$extracted_dir" || handle_error "Failed to change directory to $extracted_dir"
}


terminate_running_servers() {
  server_termination_command=${default_server_termination_command}
  eval "$server_termination_command"
  sleep 3
}


prompt_for_directories() {
  read -p "Enter the game root directory (default: '${default_game_directory}'): " game_directory
  game_directory=${game_directory:-"${default_game_directory}"}

  read -p "Where is your /legacy/ folder (default: '${default_installation_file_path}'): " installation_file_path
  installation_file_path=${installation_file_path:-"${default_installation_file_path}"}
}


move_old_snapshots() {
  old_pk3_files=$(find "$installation_file_path" -name "legacy_v2.81.1-*.pk3" -print)
  if [ -n "$old_pk3_files" ]; then
    base_name=$(basename "${old_pk3_files%%$'\n'*}")
    log_file="${CURRENT_USER:-$HOME}/legacyupdate/backup/logs/${base_name}_$(date '+%Y%m%d').log"

    echo "Old legacy PK3 files:"
    echo "$old_pk3_files"

    echo "Old legacy PK3 files:" >> "$update_log_file"
    echo "$old_pk3_files" >> "$update_log_file"

    mv $old_pk3_files "$backup_directory" >> "$log_file"
  fi
}

copy_update_contents() {
  cp -r * "$game_directory"
}

search_for_new_snapshots() {
  new_pk3_files=$(find "$game_directory" -name "legacy_v2.81.1-*.pk3" -print)
}

print_update_message() {
  if [ -n "$new_pk3_files" ]; then
    log_message "Update completed successfully!"
    updated_version=$(echo "${new_pk3_files%%$'\n'*}" | awk -F'legacy_v2.81.1-' '{print $2}' | cut -d'.' -f1-3)
    log_message "Updated to version: $updated_version"
    echo "Updated to version: $updated_version from $old_pk3_files "
    copy_new_pk3_files
  else
    log_message "No update was performed."
  fi
}


copy_new_pk3_files() {
  for file in $new_pk3_files; do
    if [ -e "$file" ]; then
      cp "$file" "/var/www/html/legacy/"
    fi
  done
}


save_logs() {
  log_message "Update process finished."
  log_message "------------------------------------"

  cd "$backup_directory" || handle_error "Failed to change directory to $backup_directory"
  rm "$update_file" >> "$update_log_file" 2>&1 || handle_error "Failed to remove the downloaded update file."
  rm -rf "$extracted_dir" >> "$update_log_file" 2>&1 || handle_error "Failed to remove the extracted directory."
}

# Main script

# Set the path for the update log file
update_log_file="${CURRENT_USER:-$HOME}/legacyupdate/backup/logs/update_$(date '+%Y%m%d%H%M%S').log"
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
download_and_extract_update

# Terminate running servers
terminate_running_servers

# Prompt the user for directories
prompt_for_directories

# Move old snapshots to the backup directory
move_old_snapshots

# Copy the contents of the update to the game directory
copy_update_contents

# Search for new snapshots
search_for_new_snapshots

# Print a message indicating the update was successful
print_update_message

# Save logs to legacyupdate directory
save_logs
