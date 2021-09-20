#!/bin/bash

RUN_OPTS=$*

CONFIG_FILE="/etc/xray/config.json"
# CONFIG_FILE="./config.json"
METHOD=1
PORT=1080

#vmess config
UUID=''
ALTER_ID=''
#dokodemo-door config
REMOTE_IP=''
REMOTE_PORT=''


vmessConfig() {
    cat > $CONFIG_FILE<<-EOF
{
  "inbounds": [{
    "port": $PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$UUID",
          "level": 1,
          "alterId": $ALTER_ID
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
EOF
}

configRelay(){
    cat > $CONFIG_FILE<<-EOF
    {
  "log": null,
  "routing": {
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked",
        "type": "field"
      }
    ]
  },
  "dns": null,
  "inbounds": [
    {
      "listen": null,
      "port": $PORT,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "$REMOTE_IP",
        "port": $REMOTE_PORT,
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {}
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "transport": null,
  "policy": {
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true
    }
  },
  "stats": {},
  "reverse": null,
  "fakeDns": null
}
EOF
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
      --config=*)
        CONFIG_FILE="${_PARAMETER#--config=}"
      ;;
      --uuid=*)
        UUID="${_PARAMETER#--uuid=}"
      ;;
      --alterid=*)
        ALTER_ID="${_PARAMETER#--alterid=}"
      ;;
      --remote_ip=*)
        REMOTE_IP="${_PARAMETER#--remote_ip=}"
      ;;
      --remote_port=*)
          REMOTE_PORT="${_PARAMETER#--remote_port=}"
        ;;
      *)
        echo "option ${_PARAMETER} is not support"
        exit 1
      ;;

    esac
done


create_server(){
  mkdir -p /etc/xray

  if [ "$METHOD" -eq 1 ]; then
      echo 'method is vmess'
      vmessConfig
  fi

  if [ "$METHOD" -eq 5 ]; then
      echo 'method is dokodemo-door'
      configRelay
  fi
}

create_server


