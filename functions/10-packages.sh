#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

function aptUpdate {
	if ask_yes_no "${purple}:: Update & upgrade system?: ${cr}"; then
		sudo apt update && sudo apt upgrade
		echo "${green}System updated.${cr}"
	else
		skipping
	fi
}

function selectReleaseVersion {
		PS3="${green}:: Make a selection: ${cr}"
		releaseSelections=(
			"Testing"
			"Unstable"
			"Quit"
		)
		select releaseSelection in "${releaseSelections[@]}"; do
			case $releaseSelection in
				"Testing")
					sudo sed -i "s/bookworm/testing/" /etc/apt/sources.list
					break
					;;	
				"Unstable")
					sudo sed -i "s/bookworm/unstable/" /etc/apt/sources.list
					break
					;;
				"Quit")
					break
					;;
				*)
					echo "${red}Invalid Option.${cr}"
					;;
			esac
		done
}

function switchRelease {
	if [[ $codename = bookworm ]]; then
		if ask_yes_no "${purple}:: Switch Debian releases? (Switch to testing or unstable?): ${cr}"; then
				selectReleaseVersion
				if ask_yes_no "${purple}:: Update && Upgrade system now?${cr}"; then
					sudo apt update && sudo apt upgrade -y
				else
					skipping
				fi
		else
			skipping
		fi
	else
		echo "${green}You are already on a non-stable version. Codename: ${codename}${cr}"
	fi
}

function installDocker {
	if ask_yes_no "${purple}:: Install docker? ${cr}"; then
		echo "${purple}Installing docker engine${cr}"

		sudo apt-get install ca-certificates curl
		sudo install -m 0755 -d /etc/apt/keyrings
		sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
		sudo chmod a+r /etc/apt/keyrings/docker.asc

		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt-get update -y
	#
	# Install all the packages from the new repository. Included docker-compose package.
	#
		sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
	#
	# User gets added to the "docker" group to allow use of the docker commands without sudo.
	#
		echo "${green}Docker successfully installed.${cr}"

		sudo usermod -aG docker $USER

		echo "${green}$USER added to group 'docker'${cr}"
	else
		skipping
	fi
}

function installPackages {
	if ask_yes_no "${purple}:: Install packages? ${cr}"; then
		if ask_yes_no "${purple}:: Install default packages? (neovim htop ncdu qemu-guest-agent git wget gcc make fzf ufw bat openssh-server)? ${cr}"; then
			sudo apt install neovim htop ncdu qemu-guest-agent git wget gcc make fzf ufw bat openssh-server
			echo "${green}Default packages successfully installed.${cr}"
			if ask_yes_no "${purple}:: Install more packages? ${cr}"; then
				read -p "${purple}Type the packages you would like to install (separated by a single space): ${cr}" packages_to_install
				sudo apt install $packages_to_install
				success
			else
				:
			fi
		else
			read -p "${purple}Type the packages you would like to install (separated by a single space): ${cr}" packages_to_install
			sudo apt install $packages_to_install
			success
		fi
	else
		skipping
	fi
}

function detectPackagesInstalled {
	detectOpenSsh
	detectDocker
	detectNeoVim
	detectBat
}	

function detectOpenSsh {
	if [ -f "/usr/sbin/sshd" ]; then 
		if ask_yes_no "${purple}:: OpenSSH installation detected, start now? ${cr}"; then
			sudo systemctl start ssh.service
			success
		else
			skipping
		fi
	else
		:
	fi
}
#
# Docker Detection
#
function detectDocker {
	if [ -f "/usr/bin/docker" ]; then 
		if ask_yes_no "${purple}:: Docker installation detected, enable now? ${cr}"; then
			sudo systemctl enable --now docker.service
			success
		else
			skipping
		fi
	else
		:
	fi
}
#
# NeoVIM Detection
#
function echoNeoVimAliases {
	echo "alias v='nvim'" >> /home/$USER/.bash_aliases
	echo "alias vi='nvim'" >> /home/$USER/.bash_aliases
	echo "alias vim='nvim'" >> /home/$USER/.bash_aliases
	echo "${green}~/.bash_aliases file modified.${cr}"
	if [ -f "/home/$USER/.bashrc" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc"; then
		echo "${green}~/.bashrc points to ~/.bash_aliases already, ~/.bashrc has not been modified.${cr}"
	else
		echo "source /home/$USER/.bash_aliases" >> /home/$USER/.bashrc
		echo "${green}~/.bashrc now points to ~/.bash_aliases, ~/.bashrc has been modified.${cr}"
	fi
}

function detectNeoVim {
	if [ -f "/usr/bin/nvim" ]; then
		nvimConfig
		if [ -f "/home/$USER/.bash_aliases" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc" && grep -qF "alias v='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vi='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vim='nvim'" "/home/$USER/.bash_aliases"; then
			:
		else
			if ask_yes_no "${purple}:: NeoVIM installation detected, do you want 'v', 'vi', and 'vim' commands to be aliased to the 'nvim' command? ${cr}"; then
				if [ -f "/home/$USER/.bash_aliases" ]; then
					echoNeoVimAliases
				else
					touch /home/$USER/.bash_aliases
					echoNeoVimAliases
				fi
			else
				skipping
			fi
		fi
	else
		:
	fi
}

function nvimConfig {
	if ask_yes_no "${purple}:: Clone nvim configuration from git?${cr}"; then
		if [ -d "/home/$USER/.config/nvim" ]; then
			echo "${red}~/.config/nvim already exists!${cr}"
			if ask_yes_no "${red}Create a backup of /home/$USER/.config/nvim and clone from git repository anyways?${cr}"; then
				mv /home/$USER/.config/nvim /home/$USER/.config/nvim.backup
				rm -rf /home/$USER/.config/nvim
				git clone https://github.com/nakouchdoge/nvim /home/$USER/.config/nvim
				if [ -d "/home/$USER/.config/nvim" ] && [ -d "/home/$USER/.config/nvim.backup" ]; then
					echo "${green}Directory nvim.backup created and new directory has been cloned from git successfully.${cr}"
					nvimEnsureConfig
				else
					echo "${red}Something went wrong.${cr}"
				fi
			else
				skipping
			fi
		else
			git clone https://github.com/nakouchdoge/nvim /home/$USER/.config/nvim
			if [ -d "/home/$USER/.config/nvim" ]; then
				echo "${green}Git repository nakouchdoge/nvim has been cloned successfully${cr}"
				nvimEnsureConfig
			else
				echo "${red}Something went wrong.${cr}"
			fi
		fi
	else
		skipping
	fi
}

function nvimEnsureConfig {
	if grep -qF "https://github.com/nakouchdoge/nvim" "/home/$USER/.config/nvim/.git/config"; then
		if ask_yes_no "${purple}:: Check if configuration is correct for nvim to work properly?${cr}"; then
			if [ -f "/usr/bin/gcc" ] || [ -f "/usr/bin/cc" ] || [ -f "/usr/bin/clang" ] || [ -f "/usr/bin/cl" ] || [ -f "/usr/bin/zig" ]; then
				echo "${green}Found C Compiler${cr}"
			else
				if ask_yes_no "${red}:: No C compiler found, install GCC?${cr}"; then
					sudo apt install gcc
				else
					skipping
				fi
			fi
			if nvim --version | grep -qF 0.9.; then
				echo "${green}Found NeoVIM Version 0.9+${cr}"
			else
				echo "${red}You might be running an older version of neovim, if you run into issues, consider updating.${cr}"
			fi
			if [ -f "/usr/bin/npm" ]; then
				echo "${green}Found NPM${cr}"
			else
				if ask_yes_no "${red}:: NPM Installation not found, install NPM?${cr}"; then
					sudo apt install npm
				else
					skipping
				fi
			fi
		fi
	fi
}
#
# Batcat Detection
#
function checkBatSymbolicExists {
	if [ -L "/home/$USER/.local/bin/bat" ] && [ -f "/home/$USER/.local/bin/bat" ]; then
		echo "${green}Bat symbolic link already exists.${cr}"
	else
		ln -s /usr/bin/batcat /home/$USER/.local/bin/bat
	fi
}

function checkBatSymbolic {
	if [ -L "/home/$USER/.local/bin/bat" ]; then
		success
	else
		echo "${red}Something went wrong. Symbolic link not created.${cr}"
	fi
}

function detectBat {
	if [ -f "/usr/bin/batcat" ] && [ $codename = bookworm ] || [ $codename = trixie ] && [ ! -f "/usr/bin/bat" ];then
		if ask_yes_no "${purple}:: Bat installation detected, do you want to create a symbolic link so the command 'bat' can be used instead of 'batcat'?${cr}"; then
			if [ -d "/home/$USER/.local/bin" ]; then
				echo "~/.local/bin directory exists already, skipping creating directory."
				checkBatSymbolicExists
				checkBatSymbolic
			else	
				mkdir /home/$USER/.local/bin
				checkBatSymbolicExists
				checkBatSymbolic
			fi
		else
			skipping
		fi
	else
		:	
	fi
}
