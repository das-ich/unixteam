#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== System and Service Information ===${NC}"
echo

# 1. OS Version
echo -e "${GREEN}OS Version:${NC}"
lsb_release -rs
echo

# 2. Landscape Client Service Status
echo -e "${YELLOW}Status of landscape-client.service:${NC}"
systemctl is-active landscape-client.service
echo

# 3. Landscape Exchange Check
echo -e "${CYAN}Landscape Client Synchronization Check:${NC}"
current_time=$(date)
echo "Current time: $current_time"
echo

if [ -f /var/log/landscape/broker.log ]; then
    # Get the last "exchange completed" line
    last_line=$(grep -i "exchanged2 completed2" /var/log/landscape/broker.log | tail -1)
    
    if [ -n "$last_line" ]; then
        echo "Last 'exchange completed' entry:"
        echo "  $last_line"
        echo

        # Try to extract timestamp from the log line
        # Landscape log format example: 2026-01-20 14:35:22,123 [INFO] ...
        if [[ $last_line =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            log_timestamp="${BASH_REMATCH[0]}"
            # Convert to seconds since epoch
            log_epoch=$(date -d "$log_timestamp" +%s 2>/dev/null)
            current_epoch=$(date +%s)

            if [ -n "$log_epoch" ] && [ "$log_epoch" -le "$current_epoch" ]; then
                diff_seconds=$((current_epoch - log_epoch))
                diff_minutes=$((diff_seconds / 60))

                if [ "$diff_minutes" -le 30 ]; then
                    echo -e "${GREEN}✅ Landscape synchronization is working (last exchange ${diff_minutes} minute(s) ago).${NC}"
                else
                    echo -e "${RED}⚠️ Landscape synchronization may be stale (last exchange ${diff_minutes} minute(s) ago).${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️ Could not parse timestamp from log entry.${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Log entry does not contain a recognizable timestamp.${NC}"
        fi
    else
        echo -e "${RED}No 'exchange completed' entries found in the log.${NC}"
    fi
else
    echo -e "${RED}Log file /var/log/landscape/broker.log not found.${NC}"
fi
echo

# 4. CrowdStrike Falcon Sensor Status
echo -e "${MAGENTA}Status of falcon-sensor service:${NC}"
if systemctl is-active --quiet falcon-sensor; then
    echo "active"
else
    echo -e "${RED}inactive or not found${NC}"
fi
echo

# 5. CrowdStrike CID
echo -e "${MAGENTA}CrowdStrike CID:${NC}"
if output=$(sudo /opt/CrowdStrike/falconctl -g --cid 2>&1); then
    echo "$output"
else
    exit_code=$?
    if [[ "$output" == *"No such file or directory"* ]] || [[ "$output" == *"not found"* ]]; then
        echo -e "${RED}falconctl not found in /opt/CrowdStrike/. CrowdStrike may not be installed.${NC}"
    else
        echo "$output"
    fi
fi
echo

echo -e "${BLUE}=== End of Report ===${NC}"
