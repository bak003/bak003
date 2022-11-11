add_user(){
    for i in {1..3};do
        for j in {1..254};do
            cd /etc/wireguard/
            cp client.conf /etc/wireguard/client$i/wg$j.conf
            wg genkey | tee temprikey | wg pubkey > tempubkey
            sed -i 's%^PrivateKey.*$%'"PrivateKey = $(cat temprikey)"'%' /etc/wireguard/client$i/wg$j.conf
            sed -i 's%^Address.*$%'"Address = 10.77.$i.$j\/32"'%' /etc/wireguard/client$i/wg$j.conf

cat >> /etc/wireguard/wg0.conf <<-EOF
[Peer]
PublicKey = $(cat tempubkey)
AllowedIPs = 10.77.$i.$j/32
EOF
    #wg set wg0 peer $(cat tempubkey) allowed-ips 10.77.$i.$j/32
    rm -f temprikey tempubkey
        done
    done
}

add_user
