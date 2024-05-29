#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

function machineInfo {
	export codename=$(grep -oP "(?<=VERSION_CODENAME=)\w+" "/etc/os-release")
	echo OS Release Codename: $codename
}

function welcomeMessage {
	echo "Welcome to nakouchdoge's post-install script for Debian"
	echo "${green}$scriptversion${cr}"
	echo ""
	echo "${red}Do not run this script as root.${cr}"
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
		skipping
	fi
}

function checkGit {
	if [ -f "/usr/bin/git" ]; then
		echo "${green}Git installed, continuing.${cr}"
		return 0
	else
		if ask_yes_no "${red}Git not installed, install now?${cr}"; then
			sudo apt install git
			if [ -f "/usr/bin/git" ]; then
				success
				return 0
			else
				echo "${red}Something went wrong, git not found.${cr}"
				return 1
			fi
		else
			echo "${red}Git must be installed to pull NeoVIM config.${cr}"
			return 1
		fi
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
				skipping
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
					sudo apt install gcc -y
				else
					skipping
				fi
			fi
			if nvim --version | grep -qF 0.9.; then
				echo "${green}Found NeoVIM Version 0.9+${cr}"
			else
				echo "${red}You might be running an older version of neovim, if you run into issues, consider updating.${cr}"
			fi
		fi
	fi
}

function mountAtBoot {
	if [ -f "/etc/fstab" ] && grep -qF "$nfsserver:$nfsdirectory $localdirectory" "/etc/fstab"; then
		echo "${green}NFS share already exists in /etc/fstab.${cr}"
	elif [ -f "/etc/fstab" ]; then
		echo "$nfsserver:$nfsdirectory $localdirectory nfs defaults 0 0" | sudo tee /etc/fstab -a
		echo "${green}/etc/fstab has been modified.${cr}"
		if ask_yes_no "Run 'systemctl daemon-reload' to apply /etc/fstab changes?"; then
			sudo systemctl daemon-reload
			success
		else
			skipping
		fi
	else
		echo "${red}Cannot find /etc/fstab. Exiting.${cr}"
	fi
}

function addNfsShare {
	if ping -c 1 "$nfsserver" &>/dev/null; then
		sleep 1
		echo "${green}Ping response from server... mounting.${cr}"
		sudo mount "${nfsserver}":"${nfsdirectory}" "${localdirectory}"
		if grep -qF "$nfsserver:$nfsdirectory $localdirectory" "/etc/mtab"; then 
			echo "${green}Successfully mounted.${cr}"
			if ask_yes_no "Mount this share on boot?"; then
				mountAtBoot
			else
				skipping
			fi
		else
			echo "${red}Check /etc/mtab, mount unsucessful.${cr}"
		fi
	else
		echo "${red}No ping response from server. Exiting.${cr}"
		exit
	fi
}

function createNfsShare {
	if [ -d "/usr/share/nfs-common" ]; then
		if ask_yes_no "${purple}:: Add an NFS share?${cr}"; then
			read -p "${purple}Enter server IP address: ${cr}" nfsserver
			read -p "${purple}Enter server's directory (e.g. /myserver/share/): ${cr}" nfsdirectory
			read -p "${purple}Enter absolute path of local directory to mount the share: ${cr}" localdirectory
			echo " "
			echo "Server IP: $nfsserver"
			echo "Server Directory: $nfsdirectory"
			echo "Local Directory: $localdirectory"
			echo " "
			if ask_yes_no "${green}Add NFS share with these parameters?${cr}"; then
				if [ -d "$localdirectory" ]; then
					addNfsShare
				else
					if ask_yes_no "${red}$localdirectory does not exist locally. Create the directory?${cr}"; then
						sudo mkdir "$localdirectory"
						addNfsShare
					else
						echo "${grey}Cancelled.${cr}"
						exit
					fi
				fi
			else
# If they answer "no" to their parameters, we re-run the function."
				createNfsShare
			fi
		else
			skipping
		fi
	else
		echo "${red}nfs-common not installed.${cr}"
		if [ ! -d "/usr/share/nfs-common" ]; then
			if ask_yes_no "${purple}:: Install nfs-common?${cr}"; then
				sudo apt install nfs-common
				if [ -d "/usr/share/nfs-common" ]; then
					success
					createNfsShare
				fi
			else
				skipping
			fi
		else
			:
		fi
	fi
}
