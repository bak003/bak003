#!/bin/bash

RUN_OPTS=$*

CONFIG_FILE="/etc/xray/config.json"
# CONFIG_FILE="./config.json"   
PORT=1080
UUID=''
ALTER_ID=''

METHOD=1
VLESS="false"
TROJAN="false"
TLS="false"
WS="false"
XTLS="false"
KCP="false"
FORWARD="false"

configV2ray() {
    mkdir -p /etc/xray
    if [[ "$TROJAN" = "true" ]]; then
        if [[ "$XTLS" = "true" ]]; then
            trojanXTLSConfig
        else
            trojanConfig
        fi
        return 0
    fi
    if [[ "$VLESS" = "false" ]]; then
        # VMESS + kcp
        if [[ "$KCP" = "true" ]]; then
            vmessKCPConfig
            return 0
        fi
        # VMESS
        if [[ "$TLS" = "false" ]]; then
            vmessConfig
        elif [[ "$WS" = "false" ]]; then
            # VMESS+TCP+TLS
            vmessTLSConfig
        # VMESS+WS+TLS
        else
            vmessWSConfig
        fi
    #VLESS
    else
        if [[ "$KCP" = "true" ]]; then
            vlessKCPConfig
            return 0
        fi
        # VLESS+TCP
        if [[ "$WS" = "false" ]]; then
            # VLESS+TCP+TLS
            if [[ "$XTLS" = "false" ]]; then
                vlessTLSConfig
            # VLESS+TCP+XTLS
            else
                vlessXTLSConfig
            fi
        # VLESS+WS+TLS
        else
            vlessWSConfig
        fi
    fi
}

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

configForward(){
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
      "port": $LOCAL_PORT,
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
      --uuid=*)
        UUID="${_PARAMETER#--uuid=}"
      ;;
      --alterid=*)
        ALTER_ID="${_PARAMETER#--alterid=}"
      ;;
      *)
        echo "option ${_PARAMETER} is not support"
        exit 1
      ;;

    esac
done

if [ "$METHOD" -eq 1 ]; then
    echo 'method is vmess'
fi

configV2ray

