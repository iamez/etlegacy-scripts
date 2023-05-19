#!/bin/bash

# Set the path for the update log file
update_log_file="/home/et/legacyupdate/backup/logs/update.log"
backup_directory="/home/et/legacyupdate/backup"

# Check if necessary directories exist, create them if not
if [ ! -d "$backup_directory/logs" ]; then
  mkdir -p "$backup_directory/logs"
fi

if [ ! -d "$backup_directory" ]; then
  mkdir -p "$backup_directory"
fi

if [ ! -f "$update_log_file" ]; then
  touch "$update_log_file"
fi

# Search for old legacy PK3 files and move them to the backup directory
old_pk3_files=$(find /home/et/etlegacy-v2.81.1-x86_64/legacy/ -name "legacy_v2.81.1-*.pk3" -print)
if [ -n "$old_pk3_files" ]; then
  echo "Old legacy PK3 files:"
  echo "$old_pk3_files"
  mv $old_pk3_files "$backup_directory" >> "$update_log_file"

fi

# Prompt the user to enter the update link
read -p "Enter the update link: " update_link >> "$update_log_file"

# go into backup directory
cd "$backup_directory" >> "$update_log_file"

# Download the update file
wget "$update_link" >> "$update_log_file"

# Extract the downloaded
update_file=$(ls *.tar.gz)
tar -zxvf "$update_file" >> "$update_log_file"

# Get the extracted directory name
extracted_dir=$(find . -maxdepth 1 -type d -name "etlegacy-v*") >> "$update_log_file"

# Navigate into the extracted directory
cd "$extracted_dir" >> "$update_log_file"

# Terminate the running servers (vektor and aim)
screen -ls | grep -E "(vektor|aim)" | awk '{print $1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit >> "$update_log_file"
sleep 10

# Copy the contents of the update to the game directory
cp -r * /home/et/etlegacy-v2.81.1-x86_64/

# Save logs to legacyupdate directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully!" >> "$update_log_file"

# Print a message indicating the update was successful
echo "Update completed successfully!"
