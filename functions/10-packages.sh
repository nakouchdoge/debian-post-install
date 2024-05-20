#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

function aptUpdate {
	if ask_yes_no "${purple}:: Update & upgrade system?: ${cr}"; then
		sudo apt update && sudo apt upgrade -y
		echo "${green}System updated.${cr}"
	else
		echo "${grey}Skipping.${cr}"
	fi
}

function switchRelease {
	if [ $codename = bookworm ]; then
		if ask_yes_no "${purple}:: Switch Debian releases? (Switch to testing or unstable?): ${cr}"; then
			PS3="${green}:: Make a selection: ${cr}"
			releaseSelections=(
				"Testing"
				"Unstable"
				"Quit"
			)
			select releaseSelection in "{$releaseSelections[@]}"; do
				case $releaseSelection in
					"Testing")
						sudo sed -i "s/bookworm/testing/" /etc/apt/sources.list
						;;	
					"Unstable")
						sudo sed -i "s/bookworm/unstable/" /etc/apt/sources.list
						;;
					"Quit")
						break
						;;
					*)
						echo "${red}Invalid Option.${cr}"
						;;
				esac
			done
			if [ $releaseSelection = Testing || $releaseSelection = Unstable ]; then
				if ask_yes_no "${purple}:: Update && Upgrade system now?${cr}"; then
					sudo apt update && sudo apt upgrade -y
				else
					echo "${grey}Skipping.${cr}"
				fi
			else
				:
			fi
		else
			echo "${grey}Skipping.${cr}"
		fi
	else
		:
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
		echo "${grey}Skipping.${cr}"
	fi
}

function installPackages {
	if ask_yes_no "${purple}:: Install packages? ${cr}"; then
		if ask_yes_no "${purple}:: Install default packages? (neovim htop neofetch ncdu qemu-guest-agent git openssh-server)? ${cr}"; then
			sudo apt install neovim htop neofetch ncdu qemu-guest-agent git openssh-server
			echo "${green}Default packages successfully installed.${cr}"
			if ask_yes_no "${purple}:: Install more packages? ${cr}"; then
				read -p "${purple}Type the packages you would like to install (separated by a single space): ${cr}" packages_to_install
				sudo apt install $packages_to_install
				echo "${green}Success${cr}"
			else
				:
			fi
		else
			read -p "${purple}Type the packages you would like to install (separated by a single space): ${cr}" packages_to_install
			sudo apt install $packages_to_install
			echo "${green}Success${cr}"
		fi
	else
		echo "${grey}Skipping.${cr}"
	fi
}

function detectPackagesInstalled {
	if [ -f "/usr/sbin/sshd" ]; then 
		if ask_yes_no "${purple}:: OpenSSH installation detected, start now? ${cr}"; then
			sudo systemctl start ssh.service
			echo "${green}Success${cr}"
		else
			echo "${grey}Skipping.${cr}"
		fi
	else
		:
	fi

	if [ -f "/usr/bin/docker" ]; then 
		if ask_yes_no "${purple}:: Docker installation detected, enable now? ${cr}"; then
			sudo systemctl enable --now docker.service
			echo "${green}Success${cr}"
		else
			echo "${grey}Skipping.${cr}"
		fi
	else
		:
	fi

	if [ -f "/usr/bin/nvim" ]; then
		if [ -f "/home/$USER/.bash_aliases" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc" && grep -qF "alias v='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vi='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vim='nvim'" "/home/$USER/.bash_aliases"; then
			:
		else
			if ask_yes_no "${purple}:: NeoVIM installation detected, do you want 'v', 'vi', and 'vim' commands to be aliased to the 'nvim' command? ${cr}"; then
				if [ -f "/home/$USER/.bash_aliases" ]; then
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
				else
					touch /home/$USER/.bash_aliases
					echo "alias v='nvim'" >> /home/$USER/.bash_aliases
					echo "alias vi='nvim'" >> /home/$USER/.bash_aliases
					echo "alias vim='nvim'" >> /home/$USER/.bash_aliases
					echo "${green}~/.bash_aliases file created and aliases added.${cr}"
					if [ -f "/home/$USER/.bashrc" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc"; then
						echo "${green}~/.bashrc points to ~/.bash_aliases already, ~/.bashrc has not been modified.${cr}"
					else
						echo "source /home/$USER/.bash_aliases" >> /home/$USER/.bashrc
						echo "${green}~/.bashrc now points to ~/.bash_aliases, ~/.bashrc has been modified.${cr}"
					fi
				fi
			else
				echo "${grey}Skipping.${cr}"
			fi
		fi
	else
		:
	fi
}
