# kvm-create-shell
快速创建kvm虚拟机的shell脚本，更改脚本中的如下配置，即可快速复制模板

VM_CONFIG_PATH="/etc/libvirt/qemu"              //kvm的xml的路径
VM_IMAGE_PATH="/kvm/vdisks"                     //虚拟硬盘的路径
VM_IMAGE_MODIFY_PATH="/kvm/modify"              //中转目录
TEMPLATE_IMAGE_NAME="test-br-network.qcow2"     //模板kvm虚拟硬盘名
TEMPLATE_CONFIG_NAME="test-br-network.xml"      //模板kvm虚拟硬盘配置名
VM_SERVER_NAME="test-br-network"                //模板kvm虚拟机名
