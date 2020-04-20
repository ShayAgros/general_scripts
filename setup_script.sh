function exec_com {
	if [[ $DEBUG -eq 1 ]]; then
		echo ${@}
		"$@"
	else
		"$@" >/dev/null 2>&1
	fi
}

# install dev tools
if grep -q "Amazon Linux" /etc/*-release >/dev/null 2>&1 ||
   grep -q "rhel" /etc/*-release >/dev/null 2>&1 ; then

	exec_com sudo yum install git vim cscope ctags iperf3 zsh gcc make ncurses-devel flex bison bc -y
	exec_com sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	exec_com sudo yum-config-manager --enable epel
	if grep -q "Amazon Linux" /etc/*-release >/dev/null 2>&1 ; then
		exec_com sudo yum install -y iperf.x86_64 htop gcc-c++
	fi
	exec_com sudo yum install kernel-devel-`uname -r` -y
	grep -q "rhel" /etc/*-release >/dev/null 2>&1 && exec_com sudo yum install elfutils-libelf-devel openssl-devel tcpdump -y
elif grep -q "ubuntu" /etc/*-release >/dev/null 2>&1 ; then
	exec_com sudo apt-get update
	exec_com sudo apt-get install build-essential -y
	exec_com sudo apt-get install git vim libssl-dev flex bison libncurses-dev cscope ctags iperf3 zsh -y
fi

# Changing default shell

exec_com sudo usermod --shell /bin/zsh `whoami`

cd
# Download and setup vim
exec_com git clone https://www.github.com/ShayAgros/myVimrc.git || exit 1
cd myVimrc
exec_com ./replace_vimrc.sh
cd

[[ -f ~/code.tar.bz2 ]] && tar xf ~/code.tar.bz2

# prevent ssh timeout
exec_com sudo bash -c 'echo -e "\tServerAliveInterval 20" >> /etc/ssh/ssh_config'

# Create an "alias" to unbinding device The use in tee needed for sudo
# no need to output it to the screen
cat << EOF | sudo tee /bin/unbind_dev >/dev/null
#!/bin/bash
echo "0000:00:06.0" | sudo tee /sys/bus/pci/drivers/ena/unbind
EOF
sudo chmod a+x /bin/unbind_dev

# Create an "alias" to binding device. The use in tee needed for sudo
# no need to output it to the screen
cat << EOF | sudo tee /bin/bind_dev >/dev/null
#!/bin/bash
echo "0000:00:06.0" | sudo tee /sys/bus/pci/drivers/ena/bind
EOF
sudo chmod a+x /bin/bind_dev

# create scripts dir
mkdir ~/scripts

# Create script to change driver name from "ena" to "testing_ena"
cat << EOF > ~/scripts/change_drv_name.sh
#!/bin/bash
sed -i '/#define DRV_MODULE_NAME/s/ena/testing_ena/' ena_netdev.h
EOF
chmod a+x ~/scripts/change_drv_name.sh

# Create a scripts to update grub
cat << EOF > ~/scripts/update_grub.sh
#!/usr/bin/env bash

set -x

sudo grub2-mkconfig -o /boot/grub2/grub.cfg

sudo grub2-set-default "$(sudo grep 'menuentry ' /boot/grub2/grub.cfg | head -n 1 | cut -f2 -d\')"
EOF
chmod a+x ~/scripts/update_grub.sh

# Create script to reload driver
cat << EOF > ~/scripts/reload_driver.sh
#!/usr/bin/env bash

if [[ ! -f \`pwd\`/ena_drv.ko ]]; then
	DRIVER_PATH='~/ena-drivers/linux'
else
	DRIVER_PATH=\`pwd\`
fi

echo reloading \${DRIVER_PATH}/ena_drv.ko

sudo rmmod ena_drv 2> /dev/null
sudo insmod \${DRIVER_PATH}/ena_drv.ko
EOF
chmod a+x ~/scripts/reload_driver.sh

# Install 'oh-my-zsh'
exec_com echo "n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" >/dev/null

zsh_themes=("bira" "af-magic" "agnoster")

# Change default theme
sed -ie 's/ZSH_THEME=".*"/ZSH_THEME="bira"/' ~/.zshrc

# Make zsh ignore untracked files in git plugins
sed -ie '/DISABLE_UNTRACKED_FILES_DIRTY/s/#//' ~/.zshrc

# Install devmem2
exec_com git clone https://github.com/hackndev/tools
exec_com gcc ~/tools/devmem2.c -o ~/devmem2


echo 'alias sip="ip -br a s"' >> ~/.zshrc
echo 'alias dmc="sudo dmesg -c"' >> ~/.zshrc
echo 'alias install_linux="git clone https://github.com/torvalds/linux.git ~/linux"' >> ~/.zshrc
echo 'alias install_net="git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/davem/net ~/net"' >> ~/.zshrc
echo 'alias tdump="sudo tcpdump -nni"' >> ~/.zshrc
echo 'alias change_drv_name="~/scripts/change_drv_name.sh"' >> ~/.zshrc
echo 'alias ins="sudo insmod"' >> ~/.zshrc
echo 'alias rmm="sudo rmmod"' >> ~/.zshrc
echo 'alias reload="~/scripts/reload_driver.sh"' >> ~/.zshrc
echo 'alias upkernel="~/scripts/update_grub.sh"' >> ~/.zshrc

echo 'cd ~/ena-drivers/linux' >> ~/.zshrc

# clean after hourselves
rm ~/code.tar.bz2 ~/setup_script.sh
