#!/bin/bash

RUN_OPTS=$*

METHOD=1 #1:create,2:edit
SERVER_CONF="https://raw.githubusercontent.com/bak003/script/master/wg/server.conf"

install_wg(){
    curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
    yum install -y dkms gcc-c++ gcc-gfortran glibc-headers glibc-devel libquadmath-devel libtool systemtap systemtap-devel
    yum -y install epel-release elrepo-release
    yum -y install yum-plugin-elrepo
    # yum -y install wireguard-dkms wireguard-tools
    yum -y install kmod-wireguard wireguard-tools
    # yum -y install qrencode
}


config_wg(){
    mkdir /etc/wireguard
    cd /etc/wireguard
    # wg genkey | tee sprivatekey | wg pubkey > spublickey
    # wg genkey | tee cprivatekey | wg pubkey > cpublickey
    # s1=$(cat sprivatekey)
    # s2=$(cat spublickey)
    # c1=$(cat cprivatekey)
    # c2=$(cat cpublickey)
    s1="YCkGwuhZDBTwNVb70sKgvR6jVfvFwFlce4FymNGqp0U="
    s2="9IySaRqxQXehuV1I8b6hZR5TAf3nmWOStt60o2qpSnA="
    # c1="iJ209HCtATywgIbnjoYK3E3pw4SeE3OTJ8IkFZmHsFA="
    # c2="VSRRRNN0dWddyvSVp2zk4VftYSdPp5dNldy2KM+cUgw="
    serverip=$(curl ipv4.icanhazip.com)
    port=7766
    # eth=$(ls /sys/class/net | grep e | head -1)
    eth=`route | grep default | awk '{print $NF}'`
    chmod 777 -R /etc/wireguard
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    

cat > /etc/wireguard/wg0.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.77.0.1/16 
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
ListenPort = $port
DNS = 8.8.8.8
MTU = 1420

EOF

    wget -q --no-check-certificate ${SERVER_CONF} -O server.conf
    cat server.conf >> /etc/wireguard/wg0.conf

    # config_client
    wg-quick up wg0
    systemctl enable wg-quick@wg0
}


config_ip(){
  eth=`route | grep default | awk '{print $NF}'`
  for i in {1..3};do
    let j=1
    for ip in ${IP_LIST};do
      iptables -t nat -A POSTROUTING -s 10.77.$i.$j -o $eth -j SNAT --to-source $ip
      let j=$j+1
    done
  done
  service iptables save
}


install(){
    install_wg
    config_wg
    config_ip
}


uninstall(){
  wg-quick down wg0
  yum remove -y wireguard-dkms wireguard-tools
  rm -rf /etc/wireguard/
  echo "卸载完成"
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
      *)
        echo "option ${_PARAMETER} is not support"
        exit 1
      ;;

    esac
done

if [ $METHOD -eq 1 ];then
    install
elif [ $METHOD -eq 2 ];then
    echo "invalid option"
else
    uninstall
fi

#clean script
rm -f install.sh