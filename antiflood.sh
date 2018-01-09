#!/bin/bash
# ig: @thelinuxchoice
check=$(/sbin/iptables -L | /bin/grep -o "antibrute") >&2

checkroot() {
    if [[ "$(id -u)" -ne 0 ]]; then
      printf ".:: Please, run this program as root!\n"
      exit 1
    fi
}
readconfig() {

    if [ ! -f "/etc/antiflood.cfg" ]; then
        printf ".:: Creating bruteforce config file (/etc/antiflood.cfg)... "
        /usr/bin/touch /etc/antiflood.cfg
        printf "ports=21,22,23,25,110,143,443\n" >> /etc/antiflood.cfg
        printf "seconds=60\n" >> /etc/antiflood.cfg
        printf "hitcount=6\n" >> /etc/antiflood.cfg
        printf "Done\n"
    fi
}
start() {

checkroot
readconfig
    if [[ $check == "" ]]; then
       source /etc/antiflood.cfg
       #Anti Brute Force
       /sbin/iptables -A INPUT -p tcp -m multiport --dports $ports -m conntrack --ctstate NEW -m recent --set --name antibrute
       /sbin/iptables -A INPUT -p tcp -m multiport --dports $ports -m conntrack --ctstate NEW -m recent --update --seconds $seconds --hitcount $hitcount -j DROP --name antibrute
       #Anti UDP flood
       /sbin/iptables -N udpflood
       /sbin/iptables -A INPUT -p udp -j udpflood
       /sbin/iptables -A udpflood -p udp -m limit --limit 50/s -j RETURN
       /sbin/iptables -A udpflood -j DROP
       #drop icmp
       /sbin/iptables -t mangle -A PREROUTING -p icmp -j DROP
       #drop fragments in all chains
       /sbin/iptables -t mangle -A PREROUTING -f -j DROP
       #limit connections per source ip
       /sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset
       #limit RST packets
       /sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
       /sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP
       #drop invalid packets
       /sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
       #drop tcp packets that are new and are not SYN
       /sbin/iptables -t mangle -A PREROUTING  -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
       #drop SYN packets with suspicios MSS value
       /sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
       #limit new TCP connections per second per source IP
       /sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
       /sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
       # Block packets with bogus TCP flags ### 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
       /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP  
       # Block spoofed packets ### 
       #/sbin/iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP 
       #/sbin/iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP  
       printf "\n.:: Anti-flood running, config:\n"
       printf "\n"
       printf "Drop icmp\n"
       printf "Drop fragments in all chains\n"
       printf "Limit connections per source ip\n"
       printf "Limit RST packets\n"
       printf "Drop invalid packets\n"
       printf "Drop tcp packets that are new and are not SYN\n"
       printf "Drop SYN packets with suspicios MSS value\n"
       printf "Limit new TCP connections per second per source IP\n"
       printf "Block packets with bogus TCP flags\n"
       printf "\n" 
       source /etc/antiflood.cfg
       printf ".:: Anti-BruteForce config:\n"
       printf "\n"
       printf "Port(s): $ports\n"
       printf "Seconds: $seconds\n"
       printf "Hitcount: $hitcount\n"
    else
       printf "\n.:: Anti-flood already running, config:\n"
       printf "\n"
       printf "Drop icmp\n"
       printf "Drop fragments in all chains\n"
       printf "Limit connections per source ip\n"
       printf "Limit RST packets\n"
       printf "Drop invalid packets\n"
       printf "Drop tcp packets that are new and are not SYN\n"
       printf "Drop SYN packets with suspicios MSS value\n"
       printf "Limit new TCP connections per second per source IP\n"
       printf "Block packets with bogus TCP flags\n" 
       printf "\n.:: Anti-BruteForce config:\n"
       source /etc/antiflood.cfg
       printf "\nPort(s): $ports\n"
       printf "Seconds: $seconds\n"
       printf "Hitcount: $hitcount\n"
       printf "\n.:: Run --config to update bruteforce rules or --stop to remove\n"
       printf "\n"
       exit 1
    fi
}
stop() {
checkroot
    if [[ $check == "" ]]; then
       printf ".:: Anti-Flood isn't running\n"
       exit 1
    else
       source /etc/antiflood.cfg
       /sbin/iptables -D INPUT -p tcp -m multiport --dports $ports -m conntrack --ctstate NEW -m recent --set --name antibrute
       /sbin/iptables -D INPUT -p tcp -m multiport --dports $ports -m conntrack --ctstate NEW -m recent --update --seconds $seconds --hitcount $hitcount -j DROP --name antibrute
       /sbin/iptables -D INPUT -p udp -j udpflood
       /sbin/iptables -D udpflood -p udp -m limit --limit 50/s -j RETURN
       /sbin/iptables -D udpflood -j DROP
       /sbin/iptables -X udpflood
       /sbin/iptables -D INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset
       /sbin/iptables -D INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
       /sbin/iptables -D INPUT -p tcp --tcp-flags RST RST -j DROP
       /sbin/iptables -t mangle -D PREROUTING -m conntrack --ctstate INVALID -j DROP
       /sbin/iptables -t mangle -D PREROUTING  -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
       /sbin/iptables -t mangle -D PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
       /sbin/iptables -D INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
       /sbin/iptables -D INPUT -p tcp -m conntrack --ctstate NEW -j DROP
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
       /sbin/iptables -t mangle -D PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP  
       #/sbin/iptables -t mangle -D PREROUTING -s 224.0.0.0/3 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 169.254.0.0/16 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 172.16.0.0/12 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 192.0.2.0/24 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 192.168.0.0/16 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 10.0.0.0/8 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 0.0.0.0/8 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 240.0.0.0/5 -j DROP 
       #/sbin/iptables -t mangle -D PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP  
       /sbin/iptables -t mangle -X
 printf ".:: Anti-Flood Stopped\n"
       exit 1
    fi
}

config() {
checkroot
    if [[ $check == "" ]]; then
       printf ".:: Starting Anti-BruteForce Config\n"
    else
       printf ".:: Remove old rules first: --stop\n"
       exit 1
    fi
default_ports="21,22,23,25,110,143,443"
default_seconds="60"
default_hitcount="6"
read -e -p "Anti-BruteForce Port(s) (Default: 21,22,23,25,110,143,443): " p
p="${p:-${default_ports}}"
read -e -p "Anti-BruteForce Seconds (Default: 60): " s
s="${s:-${default_seconds}}"
read -e -p "Anti-BruteForce Hitcount (Default: 6): " h
h="${h:-${default_hitcount}}"
    if [ ! -f "/etc/antiflood.cfg" ]; then
       /usr/bin/touch /etc/antiflood.cfg
    fi
printf "ports=$p\n" > /etc/antiflood.cfg
printf "seconds=$s\n" >> /etc/antiflood.cfg
printf "hitcount=$h\n" >> /etc/antiflood.cfg
start
}
case "$1" in --start) start ;; --stop) stop ;; --config) config ;;  *)
    checkroot
    printf ".:: Usage:sudo ./antiflood --start / --stop / --config\n"
    exit 1
esac
