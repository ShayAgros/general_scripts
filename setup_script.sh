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

	# AL2 has an old version of cmake which cannot compile clang manually
	exec_com sudo pip3 install cmake

	# AL2 has the line ID_LIKE="centos rhel fedora" for some reason. Need to
	# find a better way to distiguish centos
	#if ! grep -q "centos" /etc/*-release >/dev/null 2>&1 ; then
		exec_com sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
		exec_com sudo yum-config-manager --enable epel
	#fi
	#if grep -q "Amazon Linux" /etc/*-release >/dev/null 2>&1 ; then
		exec_com sudo yum install -y iperf htop gcc-c++ the_silver_searcher

		# xdp specific
		exec_com sudo yum install llvm clang libpcam-devel libcap-devel.x86_64 -y
	#fi
	exec_com sudo yum install kernel-devel-`uname -r` -y
	exec_com sudo yum install the_silver_searcher.x86_64 -y

	if grep -q "rhel" /etc/*-release >/dev/null 2>&1 ; then
		exec_com sudo yum install elfutils-libelf-devel openssl-devel tcpdump -y
		exec_com sudo yum install python3 -y
	fi

	# make nvim clipboard work
	exec_com sudo yum install xclip xsel -y
elif grep -q "ubuntu" /etc/*-release >/dev/null 2>&1 ; then
	exec_com sudo apt-get update
	exec_com sudo apt-get install build-essential -y
	exec_com sudo apt-get install git vim libssl-dev flex bison libncurses-dev cscope ctags \
			iperf iperf3 zsh python3-pip -y

	# xdp specific
	exec_com sudo apt-get install libelf-dev pkg-config -y

	# Set boot directory to be readble by user
	sudo chmod -R o+rx /boot/
fi

# Changing default shell

exec_com sudo usermod --shell /bin/zsh `whoami`

cd

[[ -f ~/code.tar.bz2 ]] && tar xf ~/code.tar.bz2

# prevent ssh timeout
exec_com sudo bash -c 'echo -e "\tServerAliveInterval 20" >> /etc/ssh/ssh_config'

# Create an "alias" to binding device. The use in tee needed for sudo
# no need to output it to the screen
cat << EOF | sudo tee /bin/bind_dev >/dev/null
#!/bin/bash
echo "0000:00:06.0" | sudo tee /sys/bus/pci/drivers/ena/bind
EOF
sudo chmod a+x /bin/bind_dev

# allow the change driver name from "ena" to "testing_ena" to be
# executable
chmod a+x ~/scripts/change_drv_name.sh

# Create script to grepping .config file
cat << EOF > ~/scripts/check_config.sh
#!/bin/bash
grep -i --color ${@:1} /boot/config-`uname -r`
EOF
chmod a+x ~/scripts/check_config.sh

# Create script to add ena driver to kernel build
cat << EOF > ~/scripts/add_amazon_config.sh
#!/bin/bash

if [[ ! -f .config ]]; then
	echo No config file's found, copying one from boot
	cp /boot/config-`uname -r` ./.config || exit 1
fi

echo CONFIG_NET_VENDOR_AMAZON=y >> ~/linux/.config
echo CONFIG_ENA_ETHERNET=m >>  ~/linux/.config

make -C ~/linux olddefconfig
EOF
chmod a+x ~/scripts/add_amazon_config.sh

# Allowing the grup configure scripts to be executable
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

# create dir for custom software
mkdir Software

# install neovim

# Download and setup vim
if  ! which nvim >/dev/null 2>&1; then
	exec_com echo Installing neovim stable from GitHub
	exec_com cd ~/Software
	exec_com mkdir nvim && cd nvim
	exec_com curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
	exec_com chmod u+x nvim.appimage
	exec_com ./nvim.appimage --appimage-extract
	exec_com sudo ln -s `pwd`/squashfs-root/usr/bin/nvim /bin/nvim

	exec_com pip3 install --user pynvim
fi
# Install personal git config
cd
exec_com git clone https://www.github.com/ShayAgros/myVimrc.git || exit 1
exec_com cd myVimrc
exec_com ./replace_vimrc.sh


echo 'alias sip="ip -br a s"' >> ~/.zshrc
echo 'alias dmc="sudo dmesg -c"' >> ~/.zshrc
echo 'alias dmC="sudo dmesg -C"' >> ~/.zshrc
echo 'alias install_linux="git clone https://github.com/torvalds/linux.git ~/linux"' >> ~/.zshrc
echo 'alias install_net="git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/davem/net ~/net"' >> ~/.zshrc
echo 'alias tdump="sudo tcpdump -nni"' >> ~/.zshrc
echo 'alias change_drv_name="~/scripts/change_drv_name.sh"' >> ~/.zshrc
echo 'alias ins="sudo insmod"' >> ~/.zshrc
echo 'alias rmm="sudo rmmod"' >> ~/.zshrc
echo 'alias reload="~/scripts/reload_driver.sh"' >> ~/.zshrc
echo 'alias upkernel="~/scripts/update_grub.sh"' >> ~/.zshrc
echo 'alias u="uname -r"' >> ~/.zshrc
echo 'alias cconfig="~/scripts/check_config.sh"'
echo 'alias vim=nvim' >> ~/.zshrc
echo 'alias xdps=~/scripts/configure_xdp.sh' >> ~/.zshrc
echo 'alias conf_amazon=~/scripts/add_amazon_config.sh' >> ~/.zshrc
echo 'alias compl="sudo make -j $(getconf _NPROCESSORS_ONLN) modules_install ; sudo make -j $(getconf _NPROCESSORS_ONLN) install"' >> ~/.zshrc
echo 'alias unbind_dev="~/scripts/unbind_device.sh"' >> ~/.zshrc

echo 'cd ~/ena-drivers/linux' >> ~/.zshrc

# clean after ourselves
rm ~/code.tar.bz2 ~/setup_script.sh
