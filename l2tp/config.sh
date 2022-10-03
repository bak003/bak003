read -p  "请输入端口(1-65535):" port
sed -i "2s/[0-9].*/$port/g" /etc/xl2tpd/xl2tpd.conf
sed -i "25s/[0-9].*/17\/$port/g" /etc/ipsec.conf
service xl2tpd restart