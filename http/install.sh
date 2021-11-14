#!/bin/bash

RUN_OPTS=$*

PORT=8888
METHOD=1 #1:create,2:edit


install_proxy(){
    yum install -y gcc
    wget https://github.com/tinyproxy/tinyproxy/releases/download/1.11.0/tinyproxy-1.11.0.tar.gz -O tinyproxy-1.11.0.tar.gz
    tar -xzvf tinyproxy-1.11.0.tar.gz
    cd tinyproxy-1.11.0
    ./configure
    make
    make install
}

config(){
    mkdir -p /etc/tinyproxy
    mkdir -p /var/log/tinyproxy
    chown -R nobody:nobody /var/log/tinyproxy

    cat > /etc/tinyproxy/tinyproxy.conf <<-EOF
User nobody
Group nobody
Port $PORT
BindSame yes
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
PidFile "/var/run/tinyproxy.pid"
MaxClients 1000
DisableViaHeader Yes
ConnectPort 80
ConnectPort 443
ConnectPort 563
EOF

    if [ ! -n "$USERNAME" ]; then  
        echo "IS NULL"  
    else  
        echo "BasicAuth $USERNAME $PASSWORD" >> /etc/tinyproxy/tinyproxy.conf
    fi
}

enable_service(){
    cat > /usr/lib/systemd/system/tinyproxy.service <<-EOF
[Unit]
Description=Startup script for the tinyproxy server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/tinyproxy.pid
ExecStart=/usr/local/bin/tinyproxy -c /etc/tinyproxy/tinyproxy.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tinyproxy
}


install(){
    install_proxy
    config
    enable_service
    systemctl start tinyproxy
}

edit(){
    config
    systemctl restart tinyproxy
}


echo "Current Options: $RUN_OPTS"
for _PARAMETER in $RUN_OPTS
do
    case "${_PARAMETER}" in
      --method=*)
        METHOD="${_PARAMETER#--method=}"
      ;;
      --port=*)
        PORT="${_PARAMETER#--port=}"
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