# User_Bash_Helpers
A simple shell script designed to assist Linux administrators users with common system monitoring, user management, and security tasks.
A simple, interactive Bash shell script designed to assist Linux administrators and power users with common system monitoring, user management, and security tasks.

✨ Features

This script provides a menu-driven interface with the following functions:

Create New User: Prompt for a new username and group, create the user, set secure home directory permissions (700), and prompt for a password.

Check System Health: Reports critical system metrics in real-time:

Disk Usage (Root partition)

Memory (RAM) Usage

System Load Averages (1, 5, and 15 minute)

CPU Usage Percentage with specialized alerts for High I/O Wait (potential hardware bottleneck) and High System Time (potential kernel/software inefficiency).

I/O Statistics (Requires iostat from sysstat).

Run Security Audit: Scans the /home directory for insecure world-writable files (-perm -o+w), logs findings to audit_log.txt, and requires sudo for full access.

Display Users & Groups: Shows a clean, tabulated list of system users (UID >= 1000) and all system groups.

⚙️ Requirements & Dependencies

This script is written in Bash and relies on standard GNU/Linux utilities.

Essential Packages (Must be installed):

sudo (for administrative tasks)

awk, column, getent

sysstat (This package provides the vmstat and iostat tools required for health checks.)

To ensure all dependencies are met on Debian/Ubuntu systems, run:

sudo apt update
sudo apt install coreutils sysstat


🚀 Installation and Usage

Download: Save the admin.sh file to your local machine.

Permissions: Make the script executable:

chmod +x admin.sh


Run: Because many features (User Creation, Security Audit, some Health Checks) require elevated privileges, it is highly recommended to run the script using sudo:

sudo ./admin.sh


Interact: Follow the menu prompts to perform administrative tasks.

📜 License

This project is licensed under the MIT License. See the LICENSE file for details.
