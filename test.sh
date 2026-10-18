#!/bin/bash

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}execute as sudo!${NC}"
  exit 1
fi

apt-get update -qq > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gsmartcontrol stress lm-sensors > /dev/null 2>&1

stress -c 4 -m 1 --vm-bytes 8G -t 3m -q > /dev/null 2>&1 &
STRESS_PID=$!

MAX_TEMP=0

tput civis

while kill -0 $STRESS_PID 2>/dev/null; do
    
    CURRENT_TEMP=$(sensors 2>/dev/null | awk -F'[+.]' '/°C/ {print $2}' | sort -nr | head -n 1)
    
    if [ -z "$CURRENT_TEMP" ]; then
        CURRENT_TEMP=0
    fi

    if [ "$CURRENT_TEMP" -gt "$MAX_TEMP" ]; then
        MAX_TEMP=$CURRENT_TEMP
    fi

    printf "\r${CYAN}max temp: ${YELLOW}%d°C${NC}    " "$MAX_TEMP"

    sleep 1
done

tput cnorm
