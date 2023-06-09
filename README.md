freshinstall.sh
demo: https://youtu.be/ZPRiWAug4sI

freshinstall.sh script is designed for use on a freshly installed Linux server. The script automates the installation of the et:legacy game server for multiplayer gaming, and it installs all of the necessary dependencies and packages to get the server up and running. Additionally, the script creates a background script that ensures the et:legacy server runs smoothly and without issue.

It is important to note that the freshinstall.sh script should only be run once, as it is intended to automate the initial setup of the et:legacy server. Once the server is set up, the background script will continue to run and maintain the server's operation, and the user can forget about the initial installation process. Overall, the freshinstall.sh script is a useful tool for quickly and easily setting up an et:legacy game server on a Linux machine, and ensuring it runs smoothly over time.


etdaemon.sh
is a Bash script that automatically starts and manages two ET:L servers named "Vektor" and "Aim".
using freshinstall.sh will "install" the script for you.
To use the script without freshinstall.sh, follow these steps:

Save the script to a directory on your Linux server, for example "/home/et/".
Set the "GAME_DIR" variable at the beginning of the script to the path where your ET:L game server is installed. (example GAME_DIR="/home/et/etlegacy-v2.81.1-x86_64")
Make the script executable by running the command "chmod a+x etdaemon.sh."
Start the script by running the command "./etdaemon.sh &"

Note that the script should be run as a background process and left running indefinitely.
If you need to stop the servers, you can run the command "screen -S vektor -X quit" and "screen -S aim -X quit".
The script logs its activity to /home/et/start_servers.log.
to access the server's console either use "screen -R vektor" "screen -R aim" and "Ctrl+a+a+d" to detach the sessions.


etlupdate.sh
for switching between snapshots, this script performs the following steps:

    Downloads and extracts an update file for the game server.
    Terminates the running game servers.
    Moves older files to a backup directory.
    Copies the updated files to the game directory.
    Logs the update information.
    Cleans up by removing temporary files.

The script is interactive and prompts the user for input at various stages.
It utilizes variables to store paths and commands, allowing customization. It also logs the update process to a log file for record-keeping purposes.

abs1.3.lua
this Lua script modifies the behavior of the game server by making specific changes when a client spawns in the game.
It sets the player's power-ups and health, and adds weapons with high ammo and clip count.
