# User_Bash_Helpers

## ✨ Features
- **Create New User**  
  - Prompt for username & group  
  - Automatically create group if missing  
  - Secure home directory permissions (`chmod 700`)  
  - Password setup via `passwd`

- **Check System Health**  
  - Disk usage (root partition)  
  - Memory usage (RAM %)  
  - CPU load averages (1, 5, 15 min)  
  - CPU usage % with alerts for:  
    - 🔴 High I/O Wait (>15%)  
    - 🟡 High System Time (>25%)  
  - I/O statistics via `iostat` (requires `sysstat`)

- **Run Security Audit**  
  - Scan `/home` for world-writable files (`-perm -o+w`)  
  - Save results to `audit_log.txt`  
  - Display first 10 findings

- **Display Users & Groups**  
  - Tabulated list of system users (UID ≥ 1000)  
  - Groups with GID and members

---

## ⚙️ Requirements & Dependencies
This script relies on standard GNU/Linux utilities.

**Required commands:**
- `vmstat`, `awk`, `column`, `getent`, `df`, `free`, `uptime`, `useradd`  
- `iostat` (from `sysstat` package)

**Install dependencies (Debian/Ubuntu):**
``bash
sudo apt update
sudo apt install coreutils sysstat``

## 🚀 Installation & Usage
1.Download the script:
``git clone https://github.com/RobiDobo/User_Bash_Helpers.git
cd User_Bash_Helpers``
2.Make it executable:
``chmod +x admin.sh``
3.Run with sudo (recommended):
``sudo ./admin.sh``
4.Follow the menu prompts to perform administrative tasks.


