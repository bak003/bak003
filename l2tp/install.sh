#!/bin/bash

RUN_OPTS=$*

IP=""
PSK=""
USERNAME=""
PASSWORD=""
iprange="10.7.0"

get_ip(){
	IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
}

install_l2tp(){
    yum -y install epel-release yum-utils net-tools iptables-services
	yum -y install ppp libreswan xl2tpd
    systemctl enable ipsec
    systemctl enable xl2tpd
}


pre_config(){
	cp -pf /etc/sysctl.conf /etc/sysctl.conf.bak

    echo "# Added by L2TP VPN" >> /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
    echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf
    echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf

    for each in `ls /proc/sys/net/ipv4/conf/`; do
        echo "net.ipv4.conf.${each}.accept_source_route=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.accept_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.send_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.rp_filter=0" >> /etc/sysctl.conf
    done
    sysctl -p
}

config_l2tp(){

    cat > /etc/ipsec.conf<<EOF
version 2.0

config setup
    protostack=netkey
    nhelpers=0
    uniqueids=no
    interfaces=%defaultroute
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!${iprange}.0/24

conn l2tp-psk
    rightsubnet=vhost:%priv
    also=l2tp-psk-nonat

conn l2tp-psk-nonat
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=%defaultroute
    leftid=${IP}
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=40
    dpdtimeout=130
    dpdaction=clear
    sha2-truncbug=yes
EOF

    cat > /etc/ipsec.secrets<<EOF
%any %any : PSK "${PSK}"
EOF

    cat > /etc/xl2tpd/xl2tpd.conf<<EOF
[global]
port = 1701

[lns default]
ip range = ${iprange}.2-${iprange}.254
local ip = ${iprange}.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

    cat > /etc/ppp/options.xl2tpd<<EOF
ipcp-accept-local
ipcp-accept-remote
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
hide-password
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
proxyarp
connect-delay 5000
EOF

iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
  
eth=`route | grep default | awk '{print $NF}'`
let seq=1
let j=3
for ip in ${IP_LIST};do
	iptables -t nat -A POSTROUTING -s ${iprange}.$j -o $eth -j SNAT --to-source $ip
    let j=$j+1
done
service iptables save

}

config_user(){
    cp -pf /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak

    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets<<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
EOF

    let seq=1
    let j=$i+3
    for ip in ${IP_LIST};do
      echo "$USERNAME$seq l2tpd $PASSWORD ${iprange}.$j" >>/etc/ppp/chap-secrets
      let seq=$seq+1
      let j=$j+1
    done
}


install(){
	get_ip
	install_l2tp
	pre_config
	config_l2tp
    config_user
	systemctl restart ipsec
	systemctl restart xl2tpd
}


edit(){
    config_user
    systemctl restart ipsec
	systemctl restart xl2tpd
}

echo "Current Options: $RUN_OPTS"
for _PARAMETER in $RUN_OPTS
do
    case "${_PARAMETER}" in
      --method=*)
        METHOD="${_PARAMETER#--method=}"
      ;;
      --ip=*)   #split by: ip1,ip2,ip3
        IP_LIST=$(echo "${_PARAMETER#--ip=}" | sed 's/,/\n/g' | sed '/^$/d')
      ;;
      --username=*)
        USERNAME="${_PARAMETER#--username=}"
      ;;
      --password=*)
        PASSWORD="${_PARAMETER#--password=}"
      ;;
      *)
        echo "option ${_PARAMETER} is not support"
        exit 1
      ;;

    esac
done

if [ $METHOD -eq 1 ];then
    install
elif [ $METHOD -eq 2 ];then
    edit
else
    echo "method invalid"
fi