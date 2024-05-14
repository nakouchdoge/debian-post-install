#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

function welcomeMessage {
	echo "Welcome to nakouchdoge's post-install script for Debian"
	echo "${green}Version 0.1${cr}"
}

function changeHostname {
	if ask_yes_no "${purple}:: Change hostname? ${cr}"; then
		read -p "${purple}Enter new hostname: ${cr}" new_hostname
		if [ -f "/etc/hostname" ] && [ -d "/usr/lib/systemd" ]; then 
			sudo hostnamectl hostname $new_hostname
			local hostname=$(cat /etc/hostname)
			echo "${green}Hostname is now: $hostname${cr}"
		elif [ -d "/usr/lib/systemd" ]; then
			sudo touch /etc/hostname
			echo "$new_hostname" | sudo tee "/etc/hostname"
		else
			echo "${red}Hostname file doesn't exist. Something went wrong.${cr}"
		fi
	else
		echo "${grey}Skipping.${cr}"
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
				else
					echo "${red}Something went wrong.${cr}"
				fi
			else
				echo "${grey}Skipping.${cr}"
			fi
		else
			git clone https://github.com/nakouchdoge/nvim /home/$USER/.config/nvim
			if [ -d "/home/$USER/.config/nvim" ]; then
				echo "${green}Git repository nakouchdoge/nvim has been cloned successfully${cr}"
			else
				echo "${red}Something went wrong.${cr}"
			fi
		fi
	else
		echo "${grey}Skipping.${cr}"
	fi
}
