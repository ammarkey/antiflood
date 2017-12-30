#!/bin/bash
grep=$(which grep)
iptables=$(which iptables) >&2
check=$($iptables -L | $grep -o "antiflood") >&2
touch=$(which touch) >&2

checkroot() {
    if [[ "$(id -u)" -ne 0 ]]; then
      printf ".:: Please, run this program as root!\n"
      exit 1
    fi
}
readconfig() {

    if [ ! -f "/etc/antiflood.cfg" ]; then
        printf ".:: Creating config file (/etc/antiflood.cfg)... "
        $touch /etc/antiflood.cfg
        printf "ports=21,22,23,25,80,110,143,443\n" >> /etc/antiflood.cfg
        printf "seconds=60\n" >> /etc/antiflood.cfg
        printf "hitcount=3\n" >> /etc/antiflood.cfg
        printf "Done\n"
    fi
}
start() {

checkroot
readconfig
    if [[ $check == "" ]]; then
       source /etc/antiflood.cfg
       $iptables -A INPUT -p tcp -m multiport --dports $ports -m state --state NEW -m recent --set --name antiflood --rsource
       $iptables -A INPUT -p tcp -m multiport --dports $ports -m recent --update --seconds $seconds --hitcount $hitcount --rttl --name antiflood --rsource -j REJECT --reject-with tcp-reset
       $iptables -I INPUT -p udp -j udpflood
       $iptables -A udpflood -p udp -m limit --limit 50/s -j RETURN
       $iptables -A udpflood -j DROP
       printf ".:: Anti-flood running\n"
       source /etc/antiflood.cfg
       printf "Port(s): $ports\n"
       printf "Seconds: $seconds\n"
       printf "Hitcount: $hitcount\n"
    else
       printf ".:: Already running with config:\n"
       source /etc/antiflood.cfg
       printf "Port(s): $ports\n"
       printf "Seconds: $seconds\n"
       printf "Hitcount: $hitcount\n"
       printf ".:: Run --config to update rules or --stop to remove\n"
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
       $iptables -D INPUT -p tcp -m multiport --dports $ports -m state --state NEW -m recent --set --name antiflood --rsource
       $iptables -D INPUT -p tcp -m multiport --dports $ports -m recent --update --seconds $seconds --hitcount $hitcount --rttl --name antiflood --rsource -j REJECT --reject-with tcp-reset
       $iptables -D INPUT -p udp -j udpflood
       $iptables -D udpflood -p udp -m limit --limit 50/s -j RETURN
       $iptables -D udpflood -j DROP
       printf ".:: Anti-Flood Stopped\n"
       exit 1
    fi
}

config() {
checkroot
    if [[ $check == "" ]]; then
       printf ".:: Starting Config\n"
    else
       printf ".:: Remove old rules first: --stop\n"
       exit 1
    fi
default_ports="21,22,23,25,80,110,143,443"
default_seconds="60"
default_hitcount="3"
read -e -p "Anti-Flood Port(s) (Default: 21,22,23,25,80,110,143,443): " p
p="${p:-${default_ports}}"
read -e -p "Anti-Flood Seconds (Default: 60): " s
s="${s:-${default_seconds}}"
read -e -p "Anti-Flood Hitcount (Default: 3): " h
h="${h:-${default_hitcount}}"
    if [ ! -f "/etc/antiflood.cfg" ]; then
       $touch /etc/antiflood.cfg
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
