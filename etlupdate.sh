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

# Prompt the user to enter the update link, download and extract the update file
read -p "Enter the update link: " update_link && \
echo "Update link: $update_link" >> "$update_log_file" && \
cd "$backup_directory" >> "$update_log_file" && \
wget "$update_link" >> "$update_log_file" && \
update_file=$(find . -maxdepth 1 -type f -name "etlegacy-v*") && \
tar -zxvf "$update_file" >> "$update_log_file" && \
extracted_dir=$(find . -maxdepth 1 -type d -name "etlegacy-v*") >> "$update_log_file" && \
cd "$extracted_dir" >> "$update_log_file"


#Make sure you disable your ET-Service/Server's here
#Terminate the running servers (vektor and aim)
#Comment the next line out

screen -ls | grep -E "(vektor|aim)" | awk '{print $1}' | cut -d. -f1 | xargs -I{} screen -X -S {} quit >> "$update_log_file"
sleep 10

# Copy the contents of the update to the game directory
# Change according to ur game dir!
cp -r * /home/et/etlegacy-v2.81.1-x86_64/


# Save logs to legacyupdate directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully!" >> "$update_log_file"

# Remove the downloaded update file and extracted directory
cd "$backup_directory" >> "$update_log_file"
rm "$update_file" >> "$update_log_file" 2>&1
rm -rf "$extracted_dir" >> "$update_log_file" 2>&1

# Print a message indicating the update was successful
echo "Update completed successfully!" >> "$update_log_file"
