# F31: Hiding Kali Linux [OUTDATED]

**I made a mistake with the concept of this tool. The realization of the idea turned out to be a failure.**

**The tool needs to be rewritten and improved, which I am currently doing.**


# Disclaimer

This article and tool is of an introductory nature and is intended for security professionals conducting testing under contract. The distribution of malware, disruption of systems, and violation of correspondence secrecy will be prosecuted. The author is not responsible for any damage caused by this tool.

# Mechanics

 The script performs the following operations:

1. Installing the necessary tools. iptables for FW configuration, tc from iproute2 package for shaping traffic and macchanger for MAC change
2. Hostname change. Yes, changing the hostname on Kali may seem like a mundane thing, but the default Kali hostname is one of the big triggers. You should always change the default hostname to some other hostname
3. Disabling hostname transmission via DHCP in the "Wired Connection" Network Manager configuration. Note that F31 refers to the file /etc/NetworkManager/system-connections/Wired\ connection\ 1
4. TTL increase and TTL offset +1 to bypass packet tracing during MITM attack
5. Disabling the NTP client
6. Firewall configuration. Allowing established and chained connections, blocking invalid connections, restricting ICMP traffic, blocking unexpected TCP MSS values
7. Disabling ICMP Redirect. IDS/IPS security systems can trigger on ICMP Redirect messages, which can expose the attacker.
8. MAC address randomization. A classic of the genre.
9. Traffic Shaping. Minimizes noise for careful operation of scanners so as not to overload network equipment. Limits to 30Kbit/s, 800 ms latency

## How to Use

It's simple enough, slope the repository, give the bash scripts permissions to run.

```bash
caster@kali:~$ git clone https://github.com/casterbyte/F31
caster@kali:~$ cd F31/
caster@kali:~/F31$ chmod +x F31.sh reset.sh
```
> F31 requires root privileges to run

```bash
caster@kali:~$ sudo bash F31.sh
███████ ██████   ██ 
██           ██ ███ 
█████    █████   ██ 
██           ██  ██ 
██      ██████   ██ 
                    
F31: Tool for hiding Kali Linux on the network
Author: Caster, @casterbyte, <caster@exploit.org>
Version: 1.0.0
For instructions and an example of how to use it, visit: https://github.com/casterbyte/F31
Usage: F31.sh --interface <interface> --new-hostname <hostname> [--noise-reduction]

Options:
  --interface       Specify the network interface to hide
  --new-hostname    Specify the new hostname for the system
  --noise-reduction Enable traffic shaping for noise reduction (optional)
```

The tool will expect two arguments per input. These are the system interface and the new hostname that the Kali user will want.

The argument responsible for activating traffic shaping is optional. It may not always be needed by the attacker. And traffic shaping will affect the speed of downloading files, etc. in the future. Use noise reduction wisely.

```bash
caster@kali:~/F31$ sudo bash F31.sh --interface eth0 --new-hostname ubuntu --noise-reduction
███████ ██████   ██ 
██           ██ ███ 
█████    █████   ██ 
██           ██  ██ 
██      ██████   ██ 
                    
F31: Tool for hiding Kali Linux on the network
Author: Caster, @casterbyte, <caster@exploit.org>
Version: 1.0.0
For instructions and an example of how to use it, visit: https://github.com/casterbyte/F31
[+] Tools are already installed.

[+] Changing hostname
[*] Hostname changed to ubuntu successfully.
[+] Updating /etc/hosts
[*] /etc/hosts updated successfully.

[+] Disabling hostname transfer via DHCP
[*] Hostname through DHCP disabled successfully.

[+] Disabling NTP client
[*] NTP client shut down successfully.

[+] Increasing and shifting TTL (TTL=80)
[*] TTL values adjusted successfully.

[+] Configuring firewall
[*] Allowing established and chained connections, blocking invalid connections, restricting ICMP traffic, blocking unexpected TCP MSS values
[*] Firewall configuration successfully.

[+] Disabling ICMP Redirect
[*] ICMP Redirects disabled successfully.

[+] Changing MAC
[*] Randomize MAC configured successfully.

[+] Limit data rate to 30 kbit/s and latency 600ms to minimize noise in L2/L3 scanning.
[+] WARNING: This change will severely affect the speed of file downloads. Use this shaping exactly before scanning
[+] If necessary, adjust this value yourself
[*] Traffic shaping configured successfully.
[*] Script executed successfully.
```

## Revert changes

I have prepared a special script to roll back all the settings made.

```bash
caster@kali:~/F31$ sudo bash reset.sh --interface eth0 --old-hostname kali
███████ ██████   ██ 
██           ██ ███ 
█████    █████   ██ 
██           ██  ██ 
██      ██████   ██ 
                    
F31: Tool for hiding Kali Linux on the network (Reset Script)
Author: Caster, @casterbyte, <caster@exploit.org>
Version: 1.0.0
For instructions and an example of how to use it, visit: https://github.com/casterbyte/F31

[+] Restoring MAC

[+] Enabling ICMP Redirect

[+] Enabling NTP client
[*] NTP client enabled successfully.

[+] Restoring firewall configuration

[+] Enabling hostname transfer via DHCP

[+] Resetting TTL (TTL=64)

[+] Restoring hostname
[*] Hostname restored to kali successfully.
[+] Restoring /etc/hosts
[*] /etc/hosts restored successfully.

[+] Removing traffic shaping (noise reduction)
[+] Traffic shaping removed
[*] Reset script executed successfully
```

# Outro

This tool is not a panacea, you must understand what you are doing in the infrastructure and avoid risk as much as possible.
UPD: This utility is a complete failure, and I'll be giving it new life soon.
