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
		exec_com sudo yum install -y iperf.x86_64 htop gcc-c++ the_silver_searcher.x86_64

		# xdp specific
		exec_com sudo yum install llvm clang libpcam-devel.x86_64 -y
	fi
	exec_com sudo yum install kernel-devel-`uname -r` -y
	grep -q "rhel" /etc/*-release >/dev/null 2>&1 && exec_com sudo yum install elfutils-libelf-devel openssl-devel tcpdump -y
elif grep -q "ubuntu" /etc/*-release >/dev/null 2>&1 ; then
	exec_com sudo apt-get update
	exec_com sudo apt-get install build-essential -y
	exec_com sudo apt-get install git vim libssl-dev flex bison libncurses-dev cscope ctags \
			iperf iperf3 zsh python3-pip -y

	# xdp specific
	exec_com sudo apt-get install libelf-dev pkg-config -y
fi

# Changing default shell

exec_com sudo usermod --shell /bin/zsh `whoami`

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

# allow the change driver name from "ena" to "testing_ena" to be
# executable
chmod a+x ~/scripts/change_drv_name.sh

# Create script to grepping .config file
cat << EOF > ~/scripts/check_config.sh
#!/bin/bash
grep -i --color ${@:1} /boot/config-`uname -r`
EOF
chmod a+x ~/scripts/check_config.sh

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
	echo Installing neovim stable from GitHub
	cd ~/Software
	mkdir nvim && cd nvim
	curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
	chmod u+x nvim.appimage
	./nvim.appimage --appimage-extract
	sudo ln -s `pwd`/squashfs-root/usr/bin/nvim /bin/nvim

	pip3 install --user pynvim
fi
# Install personal git config
cd
exec_com git clone https://www.github.com/ShayAgros/myVimrc.git || exit 1
cd myVimrc
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

echo 'cd ~/ena-drivers/linux' >> ~/.zshrc

# clean after hourselves
rm ~/code.tar.bz2 ~/setup_script.sh
