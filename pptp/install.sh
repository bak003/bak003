#!/bin/bash

RUN_OPTS=$*

IP_RANGE=''
RANGE_COUNT=0
USERNAME='test'
PASSWORD='test'
NUM=8
FIRST=0
SECOND=0
METHOD=1 #1:create,2:edit

install_pptp(){
    yum install -y epel-release
    yum install ppp pptpd net-tools iptables-services -y
    systemctl enable pptpd
}


pre_config(){
  cp /etc/ppp/options.pptpd /etc/ppp/options.pptpd.bak

  cat >>/etc/pptpd.conf<<EOF
option /etc/ppp/options.pptpd
logwtmp
localip 10.6.0.1
remoteip 10.6.0.2-245
EOF


  cat>/etc/ppp/options.pptpd<<EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
debug
lock
nobsdcomp
logfile /var/log/pptpd.log
EOF

  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  sysctl -p
  # iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
  
  let seq=1
    eth=`route | grep default | awk '{print $NF}'`
    for ((count=0;count<$NUM;count=count+1));
    do
        for ((i=0;i<$RANGE_COUNT;i=i+1));
        do
            let j=$count*$RANGE_COUNT+$i+3
            let first=$count+$FIRST
            let second=$i+$SECOND
            iptables -t nat -A POSTROUTING -s 10.6.0.$j -o $eth -j SNAT --to-source $IP_RANGE.$first.$second
            let seq=$seq+1
        done
    done
}

config_user(){
    let seq=1
    for ((count=0;count<$NUM;count=count+1));
    do
        for ((i=0;i<$RANGE_COUNT;i=i+1));
        do
            let j=$count*$RANGE_COUNT+$i+3
            echo "$USERNAME$seq * $PASSWORD 10.6.0.$j" >>/etc/ppp/chap-secrets
            let seq=$seq+1
        done
    done
}

install(){
    install_pptp
    pre_config
    config_user
    systemctl restart pptpd
}

edit(){
   config_user
   systemctl restart pptpd
}

echo "Current Options: $RUN_OPTS"
for _PARAMETER in $RUN_OPTS
do
    case "${_PARAMETER}" in
      --method=*)
        METHOD="${_PARAMETER#--method=}"
      ;;
      --ip-range=*)
        IP_RANGE="${_PARAMETER#--ip-range=}"
      ;;
      --range-count=*)
        RANGE_COUNT="${_PARAMETER#--range-count=}"
      ;;
      --username=*)
        USERNAME="${_PARAMETER#--username=}"
      ;;
      --password=*)
        PASSWORD="${_PARAMETER#--password=}"
      ;;
      --num=*)
        NUM="${_PARAMETER#--num=}"
      ;;
      --first=*)
        FIRST="${_PARAMETER#--first=}"
      ;;
      --second=*)
        SECOND="${_PARAMETER#--second=}"
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

#clean script
rm -f install.sh