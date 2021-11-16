#!/bin/bash

RUN_OPTS=$*

USERNAME='test'
PASSWORD='test'
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
connections 1000
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
  iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
  
  eth=`route | grep default | awk '{print $NF}'`
  let seq=1
  let j=3
  for ip in ${IP_LIST};do
    iptables -t nat -A POSTROUTING -s 10.6.0.$j -o $eth -j SNAT --to-source $ip
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
      echo "$USERNAME$seq pptpd $PASSWORD 10.6.0.$j" >>/etc/ppp/chap-secrets
      let seq=$seq+1
      let j=$j+1
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

#clean script
rm -f install.sh