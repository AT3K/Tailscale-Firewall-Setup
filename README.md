# Tailscale-Firewall-Setup
A bash script that updates UFW rules based on Tailscale’s DERP map. It fetches the DERP map, extracts IPs for a specified region, removes outdated UFW rules, and adds new ones to allow UDP traffic from those IPs to a target server. Ensures single execution and checks for required dependencies.

---

## Overview

The **Tailscale-Firewall-Setup** is a bash script designed to automate the management of UFW (Uncomplicated Firewall) rules based on Tailscale’s DERP map. It simplifies the process of ensuring that your firewall allows UDP traffic from specific Tailscale nodes to your server, based on the region of your choice.

The script performs the following:

1. **Fetches the DERP map** from Tailscale's servers.
2. **Extracts IP addresses** for a specified region.
3. **Removes outdated UFW rules** that were added by previous script executions.
4. **Adds new UFW rules** allowing UDP traffic from Tailscale nodes to your server.
5. **Ensures only one instance of the script runs** by locking it during execution.
6. **Checks for required dependencies** (`wget`, `jq`, and `ufw`).

---

## Prerequisites

Before running the script, ensure the following tools are installed on your server:

- **wget** - A command-line utility for downloading files from the web.
- **jq** - A lightweight and flexible command-line JSON processor.
- **ufw** - The Uncomplicated Firewall tool for managing firewall rules.

You can install them by running:

    sudo apt update
    sudo apt install wget jq ufw

---

## Configuration

### User-Configurable Options

At the top of the script, there are two key settings that you can modify:

1. **Region Code**:
   - **`REGION_CODE`**: This sets the region you want to allow connections from. Example: `ams` for Amsterdam, `nyc` for New York City. 
   - You can find available region codes by visiting [Tailscale DERP Map](https://login.tailscale.com/derpmap/default).

   Example:

       REGION_CODE="ams"  # Set the desired region code (e.g., "ams" for Amsterdam)

2. **Target IP:**
   - **`TARGET_IP`**: Set this to the IP address of your server or the host you want to protect with UFW rules.

   Example:

       TARGET_IP="XXX.XXX.XXX.XXX"  # Replace with your server/host IP address

---

## How to Use

1. **Clone the Repository**:
You can clone the repository to your server by running the following command:
    
        git clone https://github.com/AT3K/Tailscale-Firewall-Setup.git
        cd Tailscale-Firewall-Setup

2.	**Make the Script Executable**:

        chmod +x update_tailscale_ufw_rules.sh

3. **Run the Script**:
Execute the script as root (or using sudo) to update your UFW rules based on the region and target IP you specified.
    
        sudo ./update_tailscale_ufw_rules.sh

    
The script will:
- Check if all required tools are installed (wget, jq, ufw).
- Download the Tailscale DERP map and extract the IPs for the region you specified.
- Remove any outdated UFW rules that were previously set by the script.
- Add new UFW rules allowing UDP traffic from Tailscale nodes in the selected region.
- Reload UFW to apply the changes.
- Clean up temporary files.

 ---

## Example Output

    🌐 Downloading DERP map...
    🌍 Extracting IPs for the 'ams' region...
    🧹 Removing old UFW rules for 'Allow Tailscale Direct Connection'...
    🗑️ Deleting rule 42...
    ✅ Rule 42 deleted
    🗑️ Deleting rule 41...
    ✅ Rule 41 deleted
    🗑️ Deleting rule 40...
    ✅ Rule 40 deleted
    ➕ Adding new UFW rules...
    [New Rule] XXX.XXX.XXX.XXX 41641/udp ALLOW IN XXX.XXX.XXX.XXX  # Allow Tailscale Direct Connection
    🔄 Reloading UFW to apply changes...
    🧹 Cleaning up temporary files...
    ✅ UFW rules for Tailscale (ams region) updated successfully.


---

## Troubleshooting

- **No IPs found for the specified region**:
  If the script is unable to find IPs for the region you specified, ensure the region code is correct. You can check available region codes by visiting [Tailscale DERP Map](https://login.tailscale.com/derpmap/default).

- **Script not executing**:
  Make sure the script is executable (`chmod +x update_tailscale_ufw_rules.sh`) and you're running it as root or using `sudo`.

- **Missing dependencies**:
  Ensure `wget`, `jq`, and `ufw` are installed. You can install them using the following command:

      sudo apt install wget jq ufw

- **Firewall Rule Verification**:
  After the script has run, you can verify that the rules have been applied correctly by running:

      sudo ufw status
  This will display the active UFW rules. You should see a rule allowing UDP traffic from the Tailscale nodes’ IPs for the specified region.

---

## License

This script is released under the MIT License.
