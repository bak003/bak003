read -p  "请输入端口(1-65535):" port
sed -i "3042s/[0-9].*/$port\/tcp/g" /etc/services
sed -i "3043s/[0-9].*/$port\/udp/g" /etc/services
service pptpd restart
echo "修改成功!"