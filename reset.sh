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
echo "F31: Tool for hiding Kali Linux on the network (Reset script)"
echo "Author: Caster, @wearecaster, <casterinfosec@gmail.com>"
echo "Version: 1.0.0"
echo "For instructions and an example of how to use it, visit: https://github.com/wearecaster/F31"

# Help function
help() {
    echo -e "Usage: $0 --interface <interface> --old-hostname <hostname>"
    echo -e "\nOptions:"
    echo -e "  --interface       Specify the network interface to restore settings"
    echo -e "  --old-hostname    Specify the old hostname for the system"
}

# Display help if no arguments provided
if [ "$#" -lt 4 ]; then
    help
    exit 1
fi

# Arguments
if [ -z "$2" ] || [ -z "$4" ]; then
    echo -e "${RED}Usage: $0 --interface <interface> --old-hostname <hostname>${NC}"
    exit 1
fi

INTERFACE="$2"
HOSTNAME="$4"

# Restore original MAC
echo -e "\n${YELLOW}[+] Restoring MAC${NC}"
sudo ifconfig "${INTERFACE}" down && sudo macchanger -p "${INTERFACE}" > /dev/null 2>&1 && sudo ifconfig "${INTERFACE}" up

# Enable ICMP Redirect
echo -e "\n${YELLOW}[+] Enabling ICMP Redirect${NC}"
sudo sysctl -w net.ipv4.conf.all.accept_redirects=1 > /dev/null 2>&1
sudo sysctl -w net.ipv6.conf.all.accept_redirects=1 > /dev/null 2>&1

# Enable NTP client
echo -e "\n${YELLOW}[+] Disabling NTP client${NC}"
if sudo systemctl stop systemd-timesyncd > /dev/null 2>&1; then
    echo -e "${GREEN}[*] NTP client enabled successfully.${NC}"
else
    echo -e "${RED}[!] Error when enabling the NTP client.${NC}"
    exit 1
fi

# Restore Firewall
echo -e "\n${YELLOW}[+] Restoring firewall configuration${NC}"
sudo iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t mangle -D PREROUTING -m conntrack --ctstate INVALID -j DROP
sudo iptables -D INPUT -p icmp --icmp-type 0 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -D INPUT -p icmp --icmp-type 3 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -D INPUT -p icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -D INPUT -p icmp -j DROP
sudo iptables -t mangle -D PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

# Enable hostname through DHCP
echo -e "\n${YELLOW}[+] Enabling hostname transfer via DHCP${NC}"
sed -i '/\dhcp-send-hostname=false/d' /etc/NetworkManager/system-connections/Wired\ connection\ 1

# Reset TTL values
echo -e "\n${YELLOW}[+] Resetting TTL (TTL=64)${NC}"
sudo sysctl -w net.ipv4.ip_default_ttl=64 > /dev/null 2>&1
sudo iptables -t mangle -D PREROUTING -i "${INTERFACE}" -j TTL --ttl-inc 1

# Restore Hostname
echo -e "\n${YELLOW}[+] Restoring hostname${NC}"
if sudo hostnamectl set-hostname "${HOSTNAME}"; then
    echo -e "${GREEN}[*] Hostname restored to ${HOSTNAME} successfully.${NC}"
    echo -e "${YELLOW}[+] Restoring /etc/hosts${NC}"
    if sudo sed -i "s/127.0.1.1.*/127.0.1.1\t${HOSTNAME}/" /etc/hosts; then
        echo -e "${GREEN}[*] /etc/hosts restored successfully.${NC}"
    else
        echo -e "${RED}[!] Error restoring /etc/hosts.${NC}"
        exit 1
    fi
else
    echo -e "${RED}[!] Error restoring hostname.${NC}"
    exit 1
fi
# Remove traffic shaping
existing_qdisc=$(sudo tc qdisc show dev "${INTERFACE}" | grep -o "30Kbit" )

if [ -z "$existing_qdisc" ]; then
    echo -e "\n${YELLOW}[*] No traffic shaping configuration found${NC}"
else
    echo -e "\n${YELLOW}[+] Removing traffic shaping (noise reduction)${NC}"
    sudo tc qdisc del dev "${INTERFACE}" root > /dev/null 2>&1
    echo -e "${YELLOW}[+] Traffic shaping removed${NC}"
fi

echo -e "${GREEN}[*] Reset script executed successfully${NC}"
exit 0
