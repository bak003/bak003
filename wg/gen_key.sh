# wg genkey | tee sprivatekey | wg pubkey > spublickey

s1="YCkGwuhZDBTwNVb70sKgvR6jVfvFwFlce4FymNGqp0U="
s2="9IySaRqxQXehuV1I8b6hZR5TAf3nmWOStt60o2qpSnA="
# c1="iJ209HCtATywgIbnjoYK3E3pw4SeE3OTJ8IkFZmHsFA="
# c2="VSRRRNN0dWddyvSVp2zk4VftYSdPp5dNldy2KM+cUgw="

serverip=$(curl ipv4.icanhazip.com)
# port=$(rand 10000 60000)
port=7766

for i in {1..3};do
   for j in {1..254};do
        wg genkey | tee cprivatekey | wg pubkey > cpublickey
        # s1=$(cat sprivatekey)
        # s2=$(cat spublickey)
        c1=$(cat cprivatekey)
        c2=$(cat cpublickey)
        cat >> /root/server.conf <<-EOF
[Peer]
PublicKey = $c2
AllowedIPs = 10.77.$i.$j/32
EOF

cat > /root/client$i/client$j.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.77.$i.0/24
DNS = 8.8.8.8
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = $serverip:$port
AllowedIPs = 0.0.0.0/0, ::0/0
PersistentKeepalive = 25
EOF

done
done

