#!/bin/bash


REQUEST_SERVER="https://raw.githubusercontent.com/bak003/script/master/docker"
SYSTEM_RECOGNIZE=""

if [ -s "/etc/os-release" ];then
    os_name=$(sed -n 's/PRETTY_NAME="\(.*\)"/\1/p' /etc/os-release)

    if [ -n "$(echo ${os_name} | grep -Ei 'Debian|Ubuntu' )" ];then
        printf "Current OS: %s\n" "${os_name}"
        SYSTEM_RECOGNIZE="debian"

    elif [ -n "$(echo ${os_name} | grep -Ei 'CentOS')" ];then
        printf "Current OS: %s\n" "${os_name}"
        SYSTEM_RECOGNIZE="centos"
    else
        printf "Current OS: %s is not support.\n" "${os_name}"
    fi
elif [ -s "/etc/issue" ];then
    if [ -n "$(grep -Ei 'CentOS' /etc/issue)" ];then
        printf "Current OS: %s\n" "$(grep -Ei 'CentOS' /etc/issue)"
        SYSTEM_RECOGNIZE="centos"
    else
        printf "+++++++++++++++++++++++\n"
        cat /etc/issue
        printf "+++++++++++++++++++++++\n"
        printf "[Error] Current OS: is not available to support.\n"
    fi
else
    printf "[Error] (/etc/os-release) OR (/etc/issue) not exist!\n"
    printf "[Error] Current OS: is not available to support.\n"
fi

if [ -n "$SYSTEM_RECOGNIZE" ];then
    wget -qO- --no-check-certificate ${REQUEST_SERVER}/install_${SYSTEM_RECOGNIZE}.sh | \
        bash -s -- $*
else
    printf "[Error] Installing terminated"
    exit 1
fi

exit 0
