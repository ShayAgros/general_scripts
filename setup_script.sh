#!/usr/bin/env bash

function exec_com {
	if [[ $DEBUG -eq 1 ]] || [[ $V -eq 1 ]]; then
		echo ${@}
		"$@"
	else
		"$@" >/dev/null 2>&1
	fi
}

function is_arch {
	[ $(lscpu | awk '/Architecture:/ {print $2}') == aarch64 ]
}


# install dev tools
if grep -q "Amazon Linux" /etc/*-release >/dev/null 2>&1 ||
   grep -q "rhel" /etc/*-release >/dev/null 2>&1 ; then

	exec_com sudo yum install git vim cscope ctags iperf3 zsh gcc make ncurses-devel flex bison bc xauth automake libtool -y

	is_arch && exec_com sudo `which pip3` install --upgrade pip
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
	exec_com sudo apt-get install git vim libssl-dev flex bison libncurses-dev cscope universal-ctags \
			iperf iperf3 zsh python3-pip silversearcher-ag net-tools -y

	# xdp specific
	exec_com sudo apt-get install libelf-dev pkg-config -y
	# onload specific
	exec_com sudo apt-get install libcap-dev libmnl-dev -y

	# Set boot directory to be readable by user
	sudo chmod -R o+rx /boot/
fi

# Changing default shell

exec_com sudo usermod --shell /bin/zsh `whoami`

cd

[[ -f ~/code.tar.bz2 ]] && [[ ! -d ena-drivers ]] && tar xf ~/code.tar.bz2

# prevent ssh timeout
if ! grep -q ServerAliveInterval 20 /etc/ssh/ssh_config >/dev/null 2>&1 ; then
	exec_com sudo bash -c 'echo -e "\tServerAliveInterval 20" >> /etc/ssh/ssh_config'
fi

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
chmod a+x ~/scripts/add_amazon_config.sh

# Allowing the grup configure scripts to be executable
chmod a+x ~/scripts/update_grub.sh

if [[ ! -d ~/.oh-my-zsh ]]; then
# Install 'oh-my-zsh'
	exec_com echo "n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" >/dev/null
# don't write dirty status on command line. It makes zsh very slow for Linux
# kernel
	git config --global oh-my-zsh.hide-dirty 1
fi

zsh_themes=("bira" "af-magic" "agnoster")

# Change default theme
sed -ie 's/ZSH_THEME=".*"/ZSH_THEME="bira"/' ~/.zshrc

# Make zsh ignore untracked files in git plugins
sed -ie '/DISABLE_UNTRACKED_FILES_DIRTY/s/#//' ~/.zshrc

# Install devmem2
if [[ ! -d ~/devmem2 ]]; then
	exec_com git clone https://github.com/hackndev/tools
	exec_com gcc ~/tools/devmem2.c -o ~/devmem2
fi

# create dir for custom software
mkdir Software

# install neovim

# Download and setup vim
if  ! is_arch && ! which nvim >/dev/null 2>&1; then
	exec_com echo Installing neovim stable from GitHub
	exec_com cd ~/Software
	exec_com mkdir nvim && cd nvim
	exec_com curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
	exec_com chmod u+x nvim.appimage
	exec_com ./nvim.appimage --appimage-extract
	exec_com sudo ln -s `pwd`/squashfs-root/usr/bin/nvim /bin/nvim

	exec_com pip3 install --user pynvim

	# install node which is needed by CoC plugin
	cd ~/Software
	exec_com wget https://nodejs.org/dist/v12.18.2/node-v12.18.2-linux-x64.tar.xz
	exec_com tar xvf node-v12.18.2-linux-x64.tar.xz
	exec_com cd node-v12.18.2-linux-x64/bin
	exec_com sudo ln -s `pwd`/node /bin/
	exec_com sudo ln -s `pwd`/npm /bin/
fi

if  ! is_arch && ! which fzf >/dev/null 2>&1; then
	exec_com echo Installing fzf stable from GitHub
	exec_com cd ~/Software
	exec_com mkdir fzf && cd fzf
	exec_com wget https://github.com/junegunn/fzf/releases/download/0.24.4/fzf-0.24.4-linux_amd64.tar.gz
	exec_com tar xvf *.tar.gz

	exec_com sudo ln -s `pwd`/fzf /usr/bin
fi

cd

if [[ ! -d ~/myVimrc ]]; then
	exec_com git clone https://www.github.com/ShayAgros/myVimrc.git || exit 1
	exec_com cd myVimrc
	exec_com ./replace_vimrc.sh
fi

# set up VIM as default editor
if which nvim >/dev/null 2>&1 ; then
	echo 'export EDITOR=nvim' >> ~/.zshrc
else
	echo 'export EDITOR=vim' >> ~/.zshrc
fi

# This should allow to start X programs with sudo as well
echo 'sudo xauth add $(xauth -f ~`whoami`/.Xauthority list|tail -1)' >> ~/.zshrc
echo ''

echo 'alias sip="ip -br a s"' >> ~/.zshrc
echo 'alias dmc="sudo dmesg -c"' >> ~/.zshrc
echo 'alias dmC="sudo dmesg -C"' >> ~/.zshrc
echo 'alias install_linux="git clone https://github.com/torvalds/linux.git ~/linux"' >> ~/.zshrc
echo 'alias install_net="git clone git://git.kernel.org/pub/scm/linux/kernel/git/netdev/net.git ~/net"' >> ~/.zshrc
echo 'alias install_net_next="git clone https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git ~/net-next"' >> ~/.zshrc
echo 'alias install_github="git clone https://github.com/amzn/amzn-drivers.git ~/amzn-drivers"' >> ~/.zshrc
echo 'alias tdump="sudo tcpdump -nni"' >> ~/.zshrc
echo 'alias change_drv_name="~/scripts/change_drv_name.sh"' >> ~/.zshrc
echo 'alias ins="sudo insmod"' >> ~/.zshrc
echo 'alias rmm="sudo rmmod"' >> ~/.zshrc
echo 'alias reload="~/scripts/reload_driver.sh"' >> ~/.zshrc
echo 'alias upkernel="~/scripts/update_grub.sh"' >> ~/.zshrc
echo 'alias u="uname -r"' >> ~/.zshrc
echo 'alias cconfig="~/scripts/check_config.sh"'
# If vim exists crete an alist for it
which nvim >/dev/null 2>&1 && echo 'alias vim=nvim' >> ~/.zshrc
echo 'alias xdps=~/scripts/configure_xdp.sh' >> ~/.zshrc
echo 'alias cam=~/scripts/add_amazon_config.sh' >> ~/.zshrc
echo 'alias compl="sudo make -j $(getconf _NPROCESSORS_ONLN) modules_install ; sudo make -j $(getconf _NPROCESSORS_ONLN) install"' >> ~/.zshrc
echo 'alias unbind_dev="~/scripts/unbind_device.sh"' >> ~/.zshrc
echo 'alias ua="~/scripts/unbind_all_devices.sh"' >> ~/.zshrc

echo 'cd ~/ena-drivers/linux' >> ~/.zshrc

# clean after ourselves
rm ~/code.tar.bz2 ~/setup_script.sh
