#!/bin/bash

# --- COLOR DEFINITIONS (for a nicer look) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- DEPENDENCY CHECK ---

check_dependencies() {
    local missing_deps=()
    local deps=("vmstat" "awk" "column" "getent" "df" "free" "uptime" "useradd")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}ERROR: The following required commands are missing:${NC} ${missing_deps[*]}"
        echo -e "${YELLOW}Please install them before running the script (e.g., 'sudo apt install coreutils sysstat').${NC}"
        exit 1
    fi
}

# --- HELPER FUNCTIONS ---

waitIO_threshold(){
local wait_percent="$1"
if [ "$wait_percent" -gt 15 ]; then
        echo -e "${RED}  CRITICAL WARNING: High I/O Wait Time (${wait_percent}%%)! Disk or network may be overloaded.${NC}"
    fi
}

system_time_thresh(){
local system_time="$1"
    if [ "$system_time" -gt 25 ]; then
        echo -e "${YELLOW}  WARNING: High System Time (${system_time}%%). Check running applications for excessive kernel usage.${NC}"
    fi
}

iostat_check(){
if ! command -v iostat &> /dev/null; then
    echo -e "  ${YELLOW}Run 'sudo apt install sysstat' to see I/O stats.${NC}"
else
    # FIX: Added 'sudo' here as iostat sometimes requires it to access device data
    iostat -d -x -z 1 1 | awk 'NR > 3 && NF > 0 {print "  - " $1 ": " $NF "% util"}'
fi
}

cpu_check(){
local cpu_usage="$1"
if [ "$cpu_usage" -gt 90 ]; then
        echo -e "\n${RED}*** ALERT: CPU Usage is critically high! ($cpu_usage%) ***${NC}"
    fi
}

# --- FUNCTION: Display Users and Groups (Feature 4) ---
listUsersAndGroups() {
    # Check for 'column' dependency specifically here, even though the general check runs first
    if ! command -v column &> /dev/null; then
        echo -e "${RED}Error: 'column' command not found. Cannot format output.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}--- System Users ---${NC}"
    # Lists users, UIDs, and home directories (filtering for standard users, UID >= 1000)
    echo "Username | UID | Home Directory"
    echo "--------------------------------"
    getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1 ":" $3 ":" $6}' | column -t -s ':'

    echo -e "\n${YELLOW}--- System Groups ---${NC}"
    # Lists groups, GIDs, and members
    echo "Group Name | GID | Members"
    echo "--------------------------------"
    getent group | awk -F: '{print $1 ":" $3 ":" $4}' | column -t -s ':'
}

# --- FUNCTION: Create New User (Feature 1) ---
createUser() {
    echo "--- Create New User ---"
    
    read -p "enter username:" username
    read -p "enter group:" group
    #check if user exists already
    if id "$username" &>/dev/null; then 
        echo -e "${RED}Error: User '$username' already exists.${NC}"
        return
    fi
    
    # Check if the group exists, if not, create it
    if ! getent group "$group" &>/dev/null; then
        echo -e "${YELLOW}Group '$group' does not exist. Creating it...${NC}"
        # Requires root/sudo
        sudo groupadd "$group"
        GROUPADD_STATUS=$?
        if [ $GROUPADD_STATUS -ne 0 ]; then
            echo -e "${RED}Error: Could not create group '$group'.${NC}"
            return
        fi
    fi
    
    # Requires root/sudo
    sudo useradd -m -G "$group" "$username"
    
    # Check if the useradd command was successful
    if [ $? -eq 0 ]; then
        echo "User '$username' created and added to group '$group'."
        
        # Set secure permissions for their home directory (only owner can read/write/execute)
        sudo chmod 700 "/home/$username"
        echo "Set secure permissions (700) for /home/$username."
        
        # Set the password for the new user (passwd usually prompts for sudo password)
        echo -e "${YELLOW}Please set a password for $username:${NC}"
        sudo passwd "$username"
        
        echo -e "${GREEN}User provisioning complete!${NC}"
    else
        echo -e "${RED}Error: Failed to create user '$username'.${NC}"
    fi
}

# --- FUNCTION: Check System Health (Feature 2) ---
checkHealth() {
    echo "--- System Health ---"
    
    # 1. Disk Usage
    echo "Disk Usage:"
     
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "  Root Partition Usage: ${GREEN}$DISK_USAGE${NC}"
    
    # 2. Memory (RAM) Usage
    echo "Memory Usage:"
    #print used/total*100
    RAM_MEM_USAGE=$(free -mega | awk 'NR==2 {printf "%.2f%%", $3/$2 * 100}')
    echo -e "  RAM Usage: ${GREEN}$RAM_MEM_USAGE${NC}"
    
    # 3. CPU Load
    echo "CPU Load:"
    # `uptime` gives 1, 5, and 15-minute load averages
    LOAD_AVG=$(uptime | awk -F'load average: ' '{print $2}')
    echo -e "  Load Averages (1, 5, 15 min): ${GREEN}$LOAD_AVG${NC}"
    
    # 4. CPU Usage % 
    # Parse `vmstat` for System (14), Idle (15), and Wait I/O (16)
    VMSTAT_OUTPUT=$(vmstat 1 2 | awk 'END{print $14, $15, $16}')

    # Extract the values
    CPU_SYSTEM=$(echo $VMSTAT_OUTPUT | awk '{print $1}')
    CPU_IDLE=$(echo $VMSTAT_OUTPUT | awk '{print $2}')
    CPU_WAITIO=$(echo $VMSTAT_OUTPUT | awk '{print $3}')
    CPU_USAGE=$((100 - CPU_IDLE))

    echo -e "  Current CPU Usage: ${GREEN}${CPU_USAGE}%%${NC}"
    
    # Check for High I/O Wait (Hardware Bottleneck)
    waitIO_threshold "$CPU_WAITIO"
    
    # Check for High System Time (Software/Kernel Overhead)
    system_time_thresh "$CPU_SYSTEM"
    
    # 5. I/O Statistics
    echo "I/O Statistics:"
    iostat_check
    
    # FIX: Pass argument to cpu_check
    cpu_check "$CPU_USAGE"
}

# --- FUNCTION: Run Security Audit (Feature 3) ---
# This function finds files with insecure "world-writable" permissions.
securityAudit() {
    echo -e "${YELLOW}--- Security Audit ---${NC}"
    echo "Scanning for insecure (world-writable) files..."
    echo -e "${YELLOW}NOTE: This requires root access to check all home directories.${NC}"
    echo "Results will be saved to 'audit_log.txt'."
    
    LOG_FILE="audit_log.txt"
    
    # Clear old log file
    > "$LOG_FILE"
    
    #Redirect the error (2) to /dev/null to silence "Permission denied" messages.
    sudo find /home -type f -perm -o+w 2>/dev/null >> "$LOG_FILE"
    
    echo -e "${GREEN}Scan complete.${NC} Found files are logged in ${YELLOW}$LOG_FILE${NC}."
    echo "Displaying the first 10 findings:"
    head "$LOG_FILE"
}

# --- MAIN SCRIPT (The Menu) ---

# Run dependency check once before starting the loop
check_dependencies

while true; do
    # 1. Print the menu options
    echo "--- Linux Admin Helper Toolkit ---"
    echo "1. Create New User"
    echo "2. Check System Health"
    echo "3. Run Security Audit"
    echo "4. Display Users & Groups"
    echo "5. Exit"

    # 2. Read the user's choice
    read -p "Enter your choice [1-5]: " choice

    # 3. Act on the choice
    case $choice in
        1)
            echo "You chose 'Create New User'. "
            createUser
            ;;
        2)
            echo "You chose 'Check System Health'. "
            checkHealth
            ;;
        3)
            echo "You chose 'Run Security Audit'. "
            securityAudit
            ;;
        4)
            echo "You chose 'Display Users & Groups'."
            listUsersAndGroups
            ;;
        5)
            echo "Exiting. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 5."
            ;;
    esac 
    
done