#!/usr/bin/env bash

set -euo pipefail

################################################################################
#                           ⚙️ USER CONFIGURATION ⚙️                             #
#            Safe to modify settings in this section as needed                   #
################################################################################

# ✅ Region Configuration
REGION_CODE="ams"  # Set the desired region code where your Tailscale server/host is located (e.g., "ams" for Amsterdam)
# You can find the region codes here: https://login.tailscale.com/derpmap/default

# ✅ Target IP Configuration
TARGET_IP="XXX.XXX.XXX.XXX"  # Replace with your server/host IP address (e.g., your Tailscale server)

################################################################################
#                               ⚠️ WARNING ⚠️                                    #
#        DO NOT MODIFY ANY CODE BELOW THIS LINE - SYSTEM CRITICAL               #
################################################################################

# Lock the script to ensure only one instance runs
PIDFILE="/tmp/$(basename "${BASH_SOURCE[0]%.*}.pid")"
exec 200>"${PIDFILE}"
flock -n 200 || { echo "${BASH_SOURCE[0]} script is already running. Aborting..."; exit 1; }
PID=$$
echo "${PID}" 1>&200

# Constants and Variables
DERP_MAP_URL="https://login.tailscale.com/derpmap/default"
TEMP_DERP_JSON="/tmp/derpmap.json"
COMMENT="Allow Tailscale Direct Connection"
TAILSCALE_PORT="41641"  # The Tailscale UDP port used for direct connections (default is 41641).

# Ensure required tools are installed
echo "⚙️ Checking required tools..."
if ! command -v wget >/dev/null 2>&1; then
    echo "❌ wget is not installed. Please install it and try again."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is not installed. Please install it and try again."
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    echo "❌ ufw is not installed. Please install it and try again."
    exit 1
fi

################################################################################
#                         🌍 DOWNLOAD AND PARSE DERP MAP                        #
################################################################################

# Download the DERP map
echo "🌐 Downloading DERP map..."
if ! wget -q "$DERP_MAP_URL" -O "$TEMP_DERP_JSON"; then
    echo "❌ Failed to download DERP map from $DERP_MAP_URL. Exiting."
    exit 1
fi

# Parse IPs for the specified region
echo "🌍 Extracting IPs for the '${REGION_CODE}' region..."
REGION_IPS=$(jq -r --arg REGION_CODE "$REGION_CODE" '.Regions[] | select(.RegionCode == $REGION_CODE) | .Nodes[].IPv4' "$TEMP_DERP_JSON" || echo "")

if [[ -z "$REGION_IPS" ]]; then
    echo "❌ No IPs found for the '${REGION_CODE}' region. Exiting."
    rm -f "$TEMP_DERP_JSON"
    exit 1
fi

################################################################################
#                         🧹 REMOVE OLD UFW RULES                                #
################################################################################

# Remove outdated UFW rules for this script
echo "🧹 Removing old UFW rules for '${COMMENT}'..."
UFW_RULES=$(ufw status numbered | grep "$COMMENT" || echo "")

if [[ -n "$UFW_RULES" ]]; then
    # Reverse the order of rule numbers and delete them safely
    echo "$UFW_RULES" | awk '{print $1}' | tac | while read -r rule_num; do
        if [[ -n "$rule_num" ]]; then
            # Clean the rule number by removing square brackets
            rule_num=$(echo "$rule_num" | tr -d '[]')
            echo "🗑️ Deleting rule $rule_num..."
            # Delete the rule and print confirmation
            ufw --force delete "$rule_num" && echo "✅ Rule $rule_num deleted"
        fi
    done
else
    echo "🚫 No outdated rules found."
fi

################################################################################
#                        ➕ ADD NEW UFW RULES FOR REGION                        #
################################################################################

# Add new UFW rules for the specified region to access the target IP
echo "➕ Adding new UFW rules..."
for ip in $REGION_IPS; do
    ufw allow proto udp from "$ip" to "$TARGET_IP" port "$TAILSCALE_PORT" comment "$COMMENT"
    echo "[New Rule] $TARGET_IP $TAILSCALE_PORT/udp ALLOW IN $ip  # $COMMENT"
done

################################################################################
#                            🔄 RELOAD UFW TO APPLY CHANGES                      #
################################################################################

# Reload UFW to apply changes
echo "🔄 Reloading UFW to apply changes..."
ufw reload > /dev/null || { echo "❌ Failed to reload UFW. Exiting."; exit 1; }

################################################################################
#                            🧹 CLEANUP AND FINISH                               #
################################################################################

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -f "$TEMP_DERP_JSON"

echo "✅ UFW rules for Tailscale (${REGION_CODE} region) updated successfully."
