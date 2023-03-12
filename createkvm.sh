#!/usr/bin/env bash
# coding: utf-8
#

# ░░░░░░░░░░░░░░░░░░░░░░░░▄░░
# ░░░░░░░░░▐█░░░░░░░░░░░▄▀▒▌░
# ░░░░░░░░▐▀▒█░░░░░░░░▄▀▒▒▒▐
# ░░░░░░░▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐
# ░░░░░▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐
# ░░░▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌
# ░░▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒
# ░░▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐
# ░▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄
# ░▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒
# ▀▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒




HELPINFO="
用法: createvm [hapn]... \n
Create a virtual machine and create a fixed \n
IP address, vnc port, virtual machine name \n

\t  -h, --help            获取帮助信息\n
\t  -a, --address         设置IP地址\n
\t  -p, --port            设置vnc端口\n
\t  -n, --name            设置虚拟机名称\n

退出状态：\n
\t 0     正常\n
\t 1404  一般问题 (例如：没有对应的选项)\n
\t x403  严重问题 (例如：设置参数不正确)\n
"


options=$(getopt -l "help,autostart,address:,port:,name:" -o "h:a:p:n:" -a -- "$@")
if [ $? -ne 0 ];then
  exit 1404
fi
eval set -- "${options}"

while true;do
    case $1 in
        -h|--help)
            echo -e ${HELPINFO}
            exit 0
            ;;
        -a|--address)
            ping -c3 $2 &>/dev/null
            if [ $? -eq 0 ];then
                echo "$2 该地址好像在网络中的另外一台终端中正在使用, 请尝试其他IP地址"
                exit 1403
            fi
            NEW_MACHINES_ADDRESS=$2
            ;;
        -p|--port)
            ss -anptu | grep ":$2" &>/dev/null
            if [ $? -eq 0 ];then
                echo "$2 该端口正在使用中, 请更换端口继续"
                exit 2403
            fi
            NEW_MACHINES_VNC=$2
            ;;
        -n|--name)
            virsh list --all | grep $2 &>/dev/null
            if [ $? -eq 0 ];then
                echo "$2 虚拟机已经存在, 请更换其他虚拟机名字"
                exit 3403
            fi
            NEW_MACHINES_NAME=$2
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done

VM_CONFIG_PATH="/etc/libvirt/qemu"
VM_IMAGE_PATH="/kvm/vdisks"
VM_IMAGE_MODIFY_PATH="/kvm/modify"
TEMPLATE_IMAGE_NAME="test-br-network.qcow2"
TEMPLATE_CONFIG_NAME="test-br-network.xml"
VM_SERVER_NAME="test-br-network"

# 修改IP地址
qemu-img create -f qcow2 -b ${VM_IMAGE_PATH}/${TEMPLATE_IMAGE_NAME} ${VM_IMAGE_PATH}/${NEW_MACHINES_NAME}.qcow2
guestmount -a ${VM_IMAGE_PATH}/${NEW_MACHINES_NAME}.qcow2 -m /dev/centos/root ${VM_IMAGE_MODIFY_PATH}
sed -ri "s/^IPADDR.*/IPADDR=${NEW_MACHINES_ADDRESS}/" ${VM_IMAGE_MODIFY_PATH}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -ri "s/${VM_SERVER_NAME}/${NEW_MACHINES_NAME}/" ${VM_IMAGE_MODIFY_PATH}/etc/hostname
guestunmount ${VM_IMAGE_MODIFY_PATH}

# 构建配置文件
cp ${VM_CONFIG_PATH}/{${TEMPLATE_CONFIG_NAME},${NEW_MACHINES_NAME}.xml}
sed -ri '/name/,/name/s/test-br-network/NAME/g' ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -ri 's/<uuid>.*<\/uuid>//g' ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -ri 's/<mac\ address.*\/>//g' ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -ri 's/\/kvm\/vdisks\/test-br-network.qcow2/\/kvm\/vdisks\/NAME.qcow2/g' ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -i 's/\(port=\)'\''[0-9][0-9][0-9]*'\''/\1'\''VNCPORT'\''/g' ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -ri "s/NAME/${NEW_MACHINES_NAME}/" ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
sed -ri "s/VNCPORT/${NEW_MACHINES_VNC}/" ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
virsh define ${VM_CONFIG_PATH}/${NEW_MACHINES_NAME}.xml
virsh start ${NEW_MACHINES_NAME}