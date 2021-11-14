#!/bin/bash

RUN_OPTS=$*

IP_RANGE='180.215'
RANGE_COUNT=29
USERNAME='test'
PASSWORD='test'
NUM=8
FIRST=0
SECOND=0
METHOD=0 #0:create,1:edit

install_pptp(){
    yum install -y epel-release
    yum install ppp pptpd net-tools iptables-services -y
}


config(){
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

    let account_seq=1
    eth=`route | grep default | awk '{print $NF}'`
    for ((count=1;count<=$NUM;count=count+1));
    do
        for ((i=1;i<=$RANGE_COUNT;i=i+1));
        do
            let j=($count-1)*$RANGE_COUNT+$i+2
            let first=$count+$FIRST
            let second=$i+$SECOND
            # echo "vipgame$account_seq * vipgame321 10.6.0.$j" >>/etc/ppp/chap-secrets
            # iptables -t nat -A POSTROUTING -s 10.6.0.$j -o em1 -j SNAT --to-source $IP_RANGE.$first.$second
            echo "vipgame$account_seq * vipgame321 10.6.0.$j" >>chap-secrets
            echo "iptables -t nat -A POSTROUTING -s 10.6.0.$j -o $eth -j SNAT --to-source $IP_RANGE.$first.$second" >>ipt.sh

            let account_seq=$account_seq+1
        done
    done
}


install(){
    install_pptp
    config
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

if [ $METHOD -eq 0 ];then
    install
elif [ $METHOD -eq 1 ];then
    edit
else
    echo "method invalid"
fi