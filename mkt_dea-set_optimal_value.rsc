#
# mkt_dea-set_optimal_value.rsc
# Version: 1.0.0.0
# Author: Alex - DEA Sweden AB
# License: DEA
#

# Beep Functions
 :local doStartBeep [:parse ":beep frequency=1000 length=300ms;:delay 150ms;:beep frequency=1500 length=300ms;"];
 :local doFinishBeep [:parse ":beep frequency=1000 length=.6;:delay .5s;:beep frequency=1600 length=.6;:delay .5s;:beep frequency=2100 length=.3;:delay .3s;:beep frequency=2500 length=.3;:delay .3s;:beep frequency=2400 length=1;"];

# Play Audible Start Sequence
$doStartBeep

/ip ssh set strong-crypto=yes
/user set admin password=Dea2113!
/ip service disable telnet,ftp,www,api,api-ssl
/ip service set ssh port=2220
# /tool mac-server set allowed-interface-list=none
/tool bandwidth-server set enabled=no
/system identity set name=Kund-MKT_DEA
/ip dns set allow=yes servers=1.1.1.2,1.0.0.2
# /tool fetch url=https://cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem
# /certificate import file-name=DigiCertGlobalRootCA.crt.pem passphrase=""
# /ip dns set use-doh-server=https://1.1.1.1/dns-query verify-doh-cert=yes
/system clock set time-zone-autodetect=yes
/system ntp client set enabled=yes servers=se.pool.ntp.org
/ip cloud set ddns-enabled=yes update-time=no
# SIP Helper disable
/ip firewall service-port disable sip
# Turn off LLDP MED and MNDP - fixes the SIP problem with Gigaset phones
# /ip neighbor discovery-settings set protocol=cdp
# Change UDP timeout VOIP fix
/ip firewall connection tracking set udp-timeout=3720s
/ip dhcp-server option add name=TFTP code=150 value=0x04c0a85802
# value=0x04c0a85802 is 192.168.88.2
/ip dhcp-server network set 0 dhcp-option=TFTP


/system scheduler
add interval=1d name=autoupdate on-event=":execute script=\"/system routerboar\
    d upgrade\"\r\
    \n:delay 8s;\r\
    \n/system package update\r\
    \ncheck-for-updates once\r\
    \n:delay 1s;\r\
    \n:if ( [get status] = \"New version is available\") do={ install }" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=sep/01/2022 start-time=00:00:00
	
/system routerboard settings set auto-upgrade=yes
/system note set show-at-login=yes
/system logging action set memory memory-lines=1
/system logging action set memory memory-lines=100
/tool fetch dst-path=flash/sys-note.txt url="https://github.com/ncscarab/dea_sys/blob/3cec54c5000a23f6a74c5e709c7213eff9f2fb85/sys-logo.txt" mode=https
:delay 4s

# futureadd# :if ([/interface list print count-only where name=WAN]=0) do={/interface list add comment=defconf name=WAN}

# Default Ipv4 firewall - if its missing like on a 3XX switch
# /ip firewall filter add action=accept chain=input comment="default configuration" connection-state=established,related
# /ip firewall filter add action=accept chain=input src-address-list=allowed_to_router
# /ip firewall filter add action=accept chain=input protocol=icmp
# /ip firewall filter add action=drop chain=input
# /ip firewall address-list add address=192.168.88.2-192.168.88.254 list=allowed_to_router

# Basic DEA security - Protect the LAN devices -  if its missing like on a 3XX switch
# /ip firewall filter add action=fasttrack-connection chain=forward comment=FastTrack connection-state=established,related
# /ip firewall filter add action=accept chain=forward comment="Established, Related" connection-state=established,related
# /ip firewall filter add action=drop chain=forward comment="Drop invalid" connection-state=invalid log=yes log-prefix=invalid
/ip firewall filter add action=drop chain=forward comment="Drop tries to reach not public addresses from LAN" dst-address-list=not_in_internet in-interface=bridge log=yes log-prefix=!public_from_LAN out-interface=!bridge
# /ip firewall filter add action=drop chain=forward comment="Drop incoming packets that are not NAT`ted" connection-nat-state=!dstnat connection-state=new in-interface-list=WAN log=yes log-prefix=!NAT
# /ip firewall filter add action=jump chain=forward protocol=icmp jump-target=icmp comment="jump to ICMP filters"
/ip firewall filter add action=drop chain=forward comment="Drop incoming from internet which is not public IP" in-interface-list=WAN log=yes log-prefix=!public src-address-list=not_in_internet
# /ip firewall filter add action=drop chain=forward comment="Drop packets from LAN that do not have LAN IP" in-interface=bridge log=yes log-prefix=LAN_!LAN src-address=!192.168.88.0/24

# DEA remote access and Unifi redirect 
/ip firewall filter add action=accept chain=input disabled=no dst-port=8291 protocol=tcp place-before=2
/ip firewall filter add action=drop chain=input comment="Drop WAN incomming UDP DNS Request" dst-port=53 in-interface-list=WAN protocol=udp place-before=3
/ip firewall filter add action=drop chain=input comment="Drop WAN incomming TCP DNS Request" dst-port=53 in-interface-list=WAN protocol=tcp place-before=3

# Basic DEA security - Protect the LAN devices
/ip firewall address-list 
add address=0.0.0.0/8 comment=RFC6890 list=not_in_internet
add address=172.16.0.0/12 comment=RFC6890 list=not_in_internet
add address=192.168.0.0/16 comment=RFC6890 list=not_in_internet
add address=10.0.0.0/8 comment=RFC6890 list=not_in_internet
add address=169.254.0.0/16 comment=RFC6890 list=not_in_internet
add address=127.0.0.0/8 comment=RFC6890 list=not_in_internet
add address=224.0.0.0/4 comment=Multicast list=not_in_internet
add address=198.18.0.0/15 comment=RFC6890 list=not_in_internet
add address=192.0.0.0/24 comment=RFC6890 list=not_in_internet
add address=192.0.2.0/24 comment=RFC6890 list=not_in_internet
add address=198.51.100.0/24 comment=RFC6890 list=not_in_internet
add address=203.0.113.0/24 comment=RFC6890 list=not_in_internet
add address=100.64.0.0/10 comment=RFC6890 list=not_in_internet
add address=240.0.0.0/4 comment=RFC6890 list=not_in_internet
add address=192.88.99.0/24 comment="6to4 relay Anycast [RFC 3068]" list=not_in_internet

#Allow only needed icmp codes in "icmp" chain
/ip firewall filter add chain=icmp protocol=icmp icmp-options=0:0 action=accept comment="echo reply" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=3:0 action=accept comment="net unreachable" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=3:1 action=accept comment="host unreachable" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=3:4 action=accept comment="host unreachable fragmentation required" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=8:0 action=accept comment="allow echo request" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=11:0 action=accept comment="allow time exceed" place-before=13
/ip firewall filter add chain=icmp protocol=icmp icmp-options=12:0 action=accept comment="allow parameter bad" place-before=13
/ip firewall filter add chain=icmp action=drop comment="deny all other types" place-before=13

# DEA security - Block portscanners
/ip firewall filter add chain=input protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="Port scanners to list " disabled=no place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=fin,!syn,!rst,!psh,!ack,!urg action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="NMAP FIN Stealth scan" place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=fin,syn action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="SYN/FIN scan" place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=syn,rst action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="SYN/RST scan" place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=fin,psh,urg,!syn,!rst,!ack action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="FIN/PSH/URG scan" place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=fin,syn,rst,psh,ack,urg action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="ALL/ALL scan" place-before=13
/ip firewall filter add chain=input protocol=tcp tcp-flags=!fin,!syn,!rst,!psh,!ack,!urg action=add-src-to-address-list address-list="port scanners" address-list-timeout=2w comment="NMAP NULL scan" place-before=13
/ip firewall filter add chain=input src-address-list="port scanners" action=drop comment="dropping port scanners" disabled=no place-before=13

# Protection against DDoS
/ip firewall address-list add list=ddos-attackers
/ip firewall address-list add list=ddos-target
/ip firewall filter add action=return chain=detect-ddos dst-limit=32,32,src-and-dst-addresses/10s place-before=13
/ip firewall filter add action=add-dst-to-address-list address-list=ddos-target address-list-timeout=10m chain=detect-ddos place-before=13
/ip firewall filter add action=add-src-to-address-list address-list=ddos-attackers address-list-timeout=10m chain=detect-ddos place-before=13
/ip firewall raw add action=drop chain=prerouting dst-address-list=ddos-target src-address-list=ddos-attackers

# Protection against SYN Flood
/ip/settings/set tcp-syncookies=yes

# Protection against SYN-ACK Flood
/ip/firewall/filter add action=return chain=detect-ddos dst-limit=32,32,src-and-dst-addresses/10s protocol=tcp tcp-flags=syn,ack place-before=13

# IPV6 #
/ipv6 firewall address-list add address=fd12:672e:6f65:8899::/64 list=allowed
/ipv6 firewall filter add action=accept chain=input comment="allow established and related" connection-state=established,related
/ipv6 firewall filter add chain=input action=accept protocol=icmpv6 comment="accept ICMPv6"
/ipv6 firewall filter add chain=input action=accept protocol=udp port=33434-33534 comment="defconf: accept UDP traceroute"
/ipv6 firewall filter add chain=input action=accept protocol=udp dst-port=546 src-address=fe80::/16 comment="accept DHCPv6-Client prefix delegation."
/ipv6 firewall filter add action=drop chain=input in-interface=sit1 log=yes log-prefix=dropLL_from_public src-address=fe80::/16
/ipv6 firewall filter add action=accept chain=input comment="allow allowed addresses" src-address-list=allowed
/ipv6 firewall filter add action=drop chain=input
/ipv6 firewall address-list add address=fe80::/16 list=allowed
/ipv6 firewall address-list add address=xxxx::/48 list=allowed
/ipv6 firewall address-list add address=ff02::/16 comment=multicast list=allowed
/ipv6 firewall filter add action=accept chain=forward comment=established,related connection-state=established,related
/ipv6 firewall filter add action=drop chain=forward comment=invalid connection-state=invalid log=yes log-prefix=ipv6,invalid
/ipv6 firewall filter add action=accept chain=forward comment=icmpv6 in-interface=!sit1 protocol=icmpv6
/ipv6 firewall filter add action=accept chain=forward comment="local network" in-interface=!sit1 src-address-list=allowed
/ipv6 firewall filter add action=drop chain=forward log-prefix=IPV6
# End IPv6

/file remove [find type="backup"]

 
# Play Audible Finish Sequence
$doFinishBeep


:log warning "Firmware upgrade initiated"
/system package update
check-for-updates once
:delay 1s;
:if ( [get status] = "New version is available") do={ install }

:log warning "Routerboard upgrade initiated"
/system routerboard upgrade

:delay 3s
/file remove [find type="script"]
:file remove flash/conf.auto.rsc

# Post import delay
:delay 3s

/system reboot