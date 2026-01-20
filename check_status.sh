#!/bin/bash
DATE=`date`

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

# 3. Last 2 'exchange completed' entries in Landscape log
echo "today is $DATE"
echo -e "${CYAN}Last 2 'exchange completed' entries in Landscape log:${NC}"
if [ -f /var/log/landscape/broker.log ]; then
    grep -i "exchange completed" /var/log/landscape/broker.log | tail -2
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
# Try to run falconctl via sudo; if it fails with "command not found", handle it
if output=$(sudo /opt/CrowdStrike/falconctl -g --cid 2>&1); then
    echo "$output"
else
    exit_code=$?
    if [[ "$output" == *"No such file or directory"* ]] || [[ "$output" == *"not found"* ]]; then
        echo -e "${RED}falconctl not found in /opt/CrowdStrike/. CrowdStrike may not be installed.${NC}"
    else
        # Some other error (e.g. no CID set, but binary exists)
        echo "$output"
    fi
fi
echo

echo -e "${BLUE}=== End of Report ===${NC}"
