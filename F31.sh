#!/bin/bash

# Define colors
GREEN='\033[0;32m' # Green Color
RED='\033[0;31m' # Red Color
YELLOW='\033[1;33m' # Yellow Color
NC='\033[0m' # No Color

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] This script must be run as root.${NC}"
    exit 1
fi

# banner
echo "███████ ██████   ██ 
██           ██ ███ 
█████    █████   ██ 
██           ██  ██ 
██      ██████   ██ 
                    "
echo "F31: Tool for hiding Kali Linux on the network"
echo "Author: Caster, @wearecaster, <casterinfosec@gmail.com>"
echo "Version: 1.0.0"
echo "For instructions and an example of how to use it, visit: https://github.com/wearecaster/F31"

# Help function
help() {
    echo -e "Usage: $0 --interface <interface> --new-hostname <hostname> [--noise-reduction]"
    echo -e "\nOptions:"
    echo -e "  --interface       Specify the network interface to hide"
    echo -e "  --new-hostname    Specify the new hostname for the system"
    echo -e "  --noise-reduction Enable traffic shaping for noise reduction (optional)"
}

# Display help if no arguments provided
if [ "$#" -lt 4 ]; then
    help
    exit 1
fi

# Arguments
if [ -z "$2" ] || [ -z "$4" ]; then
    echo -e "${RED}Usage: $0 --interface <interface> --new-hostname <hostname> [--noise-reduction]${NC}"
    exit 1
fi

INTERFACE="$2"
HOSTNAME="$4"
NOISE_REDUCTION_ARG="$5"

# Install necessary tools
if command -v iptables > /dev/null 2>&1 && command -v tc > /dev/null 2>&1 && command -v macchanger > /dev/null 2>&1; then
    echo -e "${YELLOW}[+] Tools are already installed.${NC}"
else
    echo -e "${YELLOW}[+] Installing iptables, iproute2, macchanger${NC}"
    if sudo apt-get install iptables iproute2 macchanger > /dev/null 2>&1; then
        echo -e "${GREEN}[*] Tools installed successfully.${NC}"
    else
        echo -e "${RED}[!] Error installing tools.${NC}"
        exit 1
    fi
fi

# Changing hostname
echo -e "\n${YELLOW}[+] Changing hostname${NC}"
if sudo hostnamectl set-hostname "${HOSTNAME}"; then
    echo -e "${GREEN}[*] Hostname changed to ${HOSTNAME} successfully.${NC}"
else
    echo -e "${RED}[!] Error changing hostname.${NC}"
    exit 1
fi

# Disable hostname through DHCP
echo -e "\n${YELLOW}[+] Enabling hostname transfer via DHCP${NC}"
if sed -i '/\[ipv4\]/a dhcp-send-hostname=false' /etc/NetworkManager/system-connections/Wired\ connection\ 1; then
    echo -e "${GREEN}[*] Hostname through DHCP disabled successfully.${NC}"
else
    echo -e "${RED}[!] Error enabling hostname through DHCP.${NC}"
    exit 1
fi

# Disable NTP client
echo -e "\n${YELLOW}[+] Disabling NTP client${NC}"
if sudo systemctl stop systemd-timesyncd > /dev/null 2>&1; then
    echo -e "${GREEN}[*] NTP client shut down successfully.${NC}"
else
    echo -e "${RED}[!] Error when shutting down the NTP client.${NC}"
    exit 1
fi

# Increasing and shifting TTL value 
echo -e "\n${YELLOW}[+] Increasing and shifting TTL (TTL=80)${NC}"
if sudo sysctl -w net.ipv4.ip_default_ttl=80 > /dev/null 2>&1 && sudo iptables -t mangle -A PREROUTING -i "${INTERFACE}" -j TTL --ttl-inc 1 > /dev/null 2>&1; then
    echo -e "${GREEN}[*] TTL values adjusted successfully.${NC}"
else
    echo -e "${RED}[!] Error adjusting TTL values.${NC}"
    exit 1
fi

# FW Adjustment
echo -e "\n${YELLOW}[+] Configuring firewall${NC}"
echo -e "${YELLOW}[*] Allowing established and chained connections, blocking invalid connections, restricting ICMP traffic, blocking unexpected TCP MSS values${NC}"
if sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT &&
    sudo iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP &&
    sudo iptables -A INPUT -p icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT &&
    sudo iptables -A INPUT -p icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT &&
    sudo iptables -A INPUT -p icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT &&
    sudo iptables -A INPUT -p icmp -j DROP &&
    sudo iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP > /dev/null 2>&1; then
    echo -e "${GREEN}[*] Firewall configuration successfully.${NC}"
else
    echo -e "${RED}[!] Error configuration firewall.${NC}"
    exit 1
fi

# Disable ICMP Redirect
echo -e "\n${YELLOW}[+] Disabling ICMP Redirect${NC}"
if sudo sysctl -w net.ipv4.conf.all.accept_redirects=0 > /dev/null 2>&1 && sudo sysctl -w net.ipv6.conf.all.accept_redirects=0 > /dev/null 2>&1; then
    echo -e "${GREEN}[*] ICMP Redirects disabled successfully.${NC}"
else
    echo -e "${RED}[!] Error disabling ICMP Redirects.${NC}"
    exit 1
fi

# MAC Randomizing
echo -e "\n${YELLOW}[+] Changing MAC${NC}"
if sudo macchanger -r "${INTERFACE}" > /dev/null 2>&1; then
    echo -e "${GREEN}[*] Randomize MAC configured successfully.${NC}"
else
    echo -e "${RED}[!] Error configuring random MAC.${NC}"
    exit 1
fi

# Traffic shaping
if [ "$NOISE_REDUCTION_ARG" == "--noise-reduction" ]; then
    echo -e "\n${YELLOW}[+] Limit data rate to 30 kbit/s and latency 600ms to minimize noise in L2/L3 scanning.${NC}"
    echo -e "${YELLOW}[+] WARNING: This change will severely affect the speed of file downloads. Use this shaping exactly before scanning${NC}"
    echo -e "${YELLOW}[+] If necessary, adjust this value yourself${NC}"

    if sudo tc qdisc add dev "${INTERFACE}" root tbf rate 30kbit burst 30kbit latency 600ms > /dev/null 2>&1; then
        echo -e "${GREEN}[*] Traffic shaping configured successfully.${NC}"
    else
        echo -e "${RED}[!] Error configuring noise reduction.${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}[+] No noise reduction requested.${NC}"
fi

echo -e "${GREEN}[*] Script executed successfully.${NC}"
exit 0
