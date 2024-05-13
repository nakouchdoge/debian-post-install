#!/bin/bash
#
# Used for a new install of a Debian based system. Use after FAI install is completed with the serparate (fai.sh).
# This script replaces the original "install.sh". Several improvments include:
# 	- Removed hard coded variables and made them user defined.
# 	- Added more calls of the ask_yes_no function before executing changes.
# 	- Improved user choice in determining variables such as SSH port and custom SSh keys.
# 	- Removed "tn" as the default user, now uses "$USER" variable to be more agnostic.
#	- Generally cleaned up functions especially with case statements.
#	- Improved readability and notes.
#
# This is TN. github@nakouchdoge/scripts
#
#
#
# ask_yes_no function asks the user for "y" or "n", this is called multiple times in the script.
#
ask_yes_no () {
	while true; do
		read -p "$1 (y/n): " yn
		case $yn in
			[Yy]* ) return 0;;
			[Nn]* ) return 1;;
			* ) echo "Invalid response";;
		esac
	done
}
#
# Ask the user if they'd like to change the hostname of the machine.
#
if ask_yes_no ":: Change hostname?"; then
	read -p "Enter new hostname: " new_hostname
	if [ -f "/etc/hostname" ] && pacman -Q | grep -qF systemd; then
		sudo hostnamectl hostname "$new_hostname" 
	else
		echo "Hostname file doesn't exist. Something went wrong."
	fi
else
	echo "Skipping."
fi
#
# Ask the user if they'd like to install docker.
#
# User gets added to the "docker" group to allow use of the docker commands without sudo.
#
if ask_yes_no ":: Update & upgrade system?"; then
	sudo pacman -Syu
else
	echo "Skipping."
fi

if ask_yes_no ":: Install docker?"; then
	echo "Installing docker"
	sudo pacman -S docker docker-compose
	echo "Docker installed."
	echo "Adding $USER to docker group. Restart to the session for changes to apply."
	sudo usermod -aG docker "$USER" 
else
	echo "Skipping."
fi
#
# User chosen or default basic packages.
#
if ask_yes_no ":: Install packages?"; then
	if ask_yes_no ":: Install default packages? (base-devel, neovim, htop, neofetch, bat, ncdu, qemu-guest-agent, git, openssh)?"; then
		echo "Installing default pacakges."
		sudo pacman -S base-devel neovim htop neofetch bat ncdu qemu-guest-agent git openssh
		if ask_yes_no ":: Install more packages?"; then
			read -p "Type the packages you would like to install (separated by a single space): " packages_to_install
			sudo pacman -S "$packages_to_install"
		else
			:
		fi
	else
		read -p "Type the packages you would like to install (separated by a single space): " packages_to_install
		sudo pacman -S "$packages_to_install"
	fi
else
	echo "No packages chosen for install. Skipping."
fi
#
# Detect and ask if the user wants to enable these services in systemd
#
if pacman -Qe | grep -qF openssh; then
	if ask_yes_no ":: OpenSSH installation detected, enable now?"; then
		sudo systemctl enable --now sshd
	else
		echo "Skipping."
	fi
fi

if pacman -Qe | grep -qF docker; then
	if ask_yes_no ":: Docker installation detected, enable now?"; then
		sudo systemctl enable --now docker.service
	else
		:
	fi
fi

if [ -f "/usr/bin/nvim" ]; then
	if [ -f "/home/$USER/.bash_aliases" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc" && grep -qF "alias v='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vi='nvim'" "/home/$USER/.bash_aliases" && grep -qF "alias vim='nvim'" "/home/$USER/.bash_aliases"; then
		:
	else
		if ask_yes_no ":: NeoVIM installation detected, do you want 'v', 'vi', and 'vim' commands to be aliased to the 'nvim' command?"; then
			if [ -f "/home/$USER/.bash_aliases" ]; then
				echo "alias v='nvim'" >> /home/$USER/.bash_aliases
				echo "alias vi='nvim'" >> /home/$USER/.bash_aliases
				echo "alias vim='nvim'" >> /home/$USER/.bash_aliases
				echo "~/.bash_aliases file modified."
				if [ -f "/home/$USER/.bashrc" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc"; then
					echo "~/.bashrc points to ~/.bash_aliases already, ~/.bashrc has not been modified."
				else
					echo "source /home/$USER/.bash_aliases" >> /home/$USER/.bashrc
					echo "~/.bashrc now points to ~/.bash_aliases, ~/.bashrc has been modified."
				fi
			else
				touch /home/$USER/.bash_aliases
				echo "alias v='nvim'" >> /home/$USER/.bash_aliases
				echo "alias vi='nvim'" >> /home/$USER/.bash_aliases
				echo "alias vim='nvim'" >> /home/$USER/.bash_aliases
				echo "~/.bash_aliases file created and aliases added."
				if [ -f "/home/$USER/.bashrc" ] && grep -qF "source /home/$USER/.bash_aliases" "/home/$USER/.bashrc"; then
					echo "~/.bashrc points to ~/.bash_aliases already, ~/.bashrc has not been modified."
				else
					echo "source /home/$USER/.bash_aliases" >> /home/$USER/.bashrc
					echo "~/.bashrc now points to ~/.bash_aliases, ~/.bashrc has been modified."
				fi
			fi
		else
			echo "Skipping."
		fi
	fi
else
	:
fi
#if pacman -Qe | grep -qF neovim; then
#	if ask_yes_no ":: NeoVIM installation detected, do you want 'v' 'vi' and 'vim' to be aliases for the 'nvim' command?"; then
#		if grep "alias vi='nvim'" /home/$USER/.bashrc && grep "alias vim='nvim'" /home/$USER/.bashrc && grep "alias v='nvim'" /home/$USER/.bashrc; then
#			echo "Aliases already exist. Skipping."
#		else
#			echo "alias v='nvim'" >> /home/$USER/.bashrc
#			echo "alias vi='nvim'" >> /home/$USER/.bashrc
#			echo "alias vim='nvim'" >> /home/$USER/.bashrc
#		fi
#	else
#		echo "Skipping."
#	fi
#else
#	:
#fi
#
# *TESTING*
#
# Arch bash prompt: PS1='\[\e[96m\]\u\[\e[96m\]@\[\e[96m\]\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '
# Ask to install the custom bash prompt. This is an "Arch blue" prompt.
#
if ask_yes_no ":: Add custom arch bash prompt?"; then
#	if [ -f "/home/$USER/.bashrc" ] && grep -qF "PS1" "/home/$USER/.bashrc"; then
	if [ -f "/home/$USER/.bashrc" ]; then
		if [ -f "/home/$USER/.bash_prompt" ]; then
			mv /home/$USER/.bash_prompt /home/$USER/.bash_prompt.bak
			echo "PS1='\[\e[96m\]\u\[\e[96m\]@\[\e[96m\]\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bash_prompt
			echo ".bash_prompt backed up and custom prompt added"
			if grep -qF "source /home/$USER/.bash_prompt" "/home/$USER/.bashrc"; then
				echo "Custom prompt source file exists in .bashrc. Skipping."
			else
				echo "source /home/$USER/.bash_prompt" >> /home/$USER/.bashrc
				echo "Added source line to .bashrc"
			fi
		else
			touch /home/$USER/.bash_prompt
			echo "PS1='\[\e[96m\]\u\[\e[96m\]@\[\e[96m\]\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bash_prompt
			if grep -qF "source /home/$USER/.bash_prompt" "/home/$USER/.bashrc"; then
				echo "Custom prompt source file exists in .bashrc. Skipping."
			else
				echo "source /home/$USER/.bash_prompt" >> /home/$USER/.bashrc
				echo "Added source line to .bashrc"
			fi
		fi
	else
		echo ".bashrc ddoes not exist! Something went wrong."
	fi
else
	echo "Skipping."
fi
#
# Ask the user if they'd like to add an automatic session timeout in a user defined number of seconds.
#
if ask_yes_no ":: Set a console timeout?"; then
	read -p "Enter timeout in seconds: " tmout_seconds
	if [ -f "/home/$USER/.bashrc" ]; then
		if grep -qF "TMOUT=$tmout_seconds" "/home/$USER/.bashrc"; then
			echo "TMOUT=$tmout_seconds already exists in ~/.bashrc. Skipping."
		elif grep -qF "TMOUT=" "/home/$USER/.bashrc"; then
			if ask_yes_no ":: A timeout already exists in ~/.bashrc. Overwrite?"; then
				sed -i "s/TMOUT.*/TMOUT=$tmout_seconds/" ~/.bashrc
				echo "A $tmout_seconds second timeout has been added and will be applied on next login or by running a new shell."
			else
				echo "Skipping."
			fi
		else
			echo "TMOUT=$tmout_seconds" >> /home/$USER/.bashrc
			echo "A $tmout_seconds second timeout has been added and will be applied on next login or by running a new shell."
		fi
	else
        	echo ".bashrc does not exist. Something went wrong."
	fi
else
	echo "Skipping console timeout setting."
fi
#
# Create and configure SSH directories.
#
echo "Creating SSH directory..."

if [ -d "/home/$USER/.ssh" ]; then
	echo ".ssh directory exists, skipping"
else
	echo "Creating /home/$USER/.ssh directory"
	mkdir "/home/$USER/.ssh"
	sudo chown -R $USER /home/$USER/.ssh
fi
#
# Calling ssh_key_setup() will ask the user to input an SSH key to be appended to the ~/.ssh/authorized_keys file. It will then ask if the
# user would like to add another key until the user answers no to the "Add another" prompt.
#
ssh_key_setup() {
	while true; do
		read -p "Input SSH key (one at a time):  " user_ssh_key
		echo "$user_ssh_key" >> /home/$USER/.ssh/authorized_keys		
		read -p "Add another? (y/n): " choice
		case $choice in
			[Yy]* ) continue;;
			[Nn]* ) break;;
			* ) echo "You must answer (y/n)"
		esac
	done
}
#
# Backup any authorized_keys file that may exist and create a new one with user defined keys.
# 
if ask_yes_no ":: Modify authorized SSH keys? This will create a backup of ~/.ssh/authorized_keys and create a new one."; then
	echo "Creating ~/.ssh/authorized_keys"
	if [ -f "/home/$USER/.ssh/authorized_keys" ]; then
		mv /home/$USER/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys.old
		echo "Moved old authorized_keys file to authorized_keys.old"
	else
		echo "Creating authorized_keys file"
	fi
	touch /home/$USER/.ssh/authorized_keys
	sudo chown -R $USER /home/$USER/.ssh
	ask_yes_no ":: Input SSH keys? (At least one is required for key authentication!) :"
	ssh_key_setup
else
	echo "Skipping."
fi
#
# Ask user if they want to modify the default SSH port.
#
if ask_yes_no ":: Change SSH port?"; then
	read -p "Port to use for SSH: " ssh_port
	echo "Changing default SSH port to $ssh_port."
	if [ -f "/etc/ssh/sshd_config" ]; then
		sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
		sudo sed -i "s/.*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
		echo "SSH changed to port $ssh_port"
	else
		echo "/etc/ssh/sshd_config does not exist. Something went wrong."
	fi
else
	echo "Skipping." 
fi
#
# Add standard SSH security settings
#
if ask_yes_no ":: Change SSH security config?"; then
	echo "Securing SSH for key-based authentication and removing root login."
	if [ -f "/etc/ssh/sshd_config.d/10-security.conf" ]; then
		sudo mv /etc/ssh/sshd_config.d/10-security.conf /etc/ssh/sshd_config.d/10-security.conf.old
		sudo touch /etc/ssh/sshd_config.d/10-security.conf
		sudo echo "#Override for any other .conf files that may appear here to ensure password authentication and root login is prohibited" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PermitEmptyPasswords no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PubkeyAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "ChallengeResponseAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "UsePAM no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "Port $ssh_port" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		echo "Backed up old 10-security.conf (10-security.conf.old) file and created a new one default rules"
	else
		sudo touch /etc/ssh/sshd_config.d/10-security.conf
		sudo echo "#Override for any other .conf files that may appear here to ensure password authentication and root login is prohibited" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PermitEmptyPasswords no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "PubkeyAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "ChallengeResponseAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "UsePAM no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		sudo echo "Port $ssh_port" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
		echo "Created 10-security.conf file with default rules"
	fi
else
	echo "Skipping."
fi

if ask_yes_no ":: Restart sshd.service? If you changed the security config, you should answer yes."; then
	echo "Restarting sshd.service"
	sudo systemctl restart sshd
	sleep 3
	echo "Restarted sshd.service"
else
	echo "Skipping."
fi
#
# Firewall setup function below. Easier syntax than typing out the commands. Will ask infinitely until the user answers "n".
#
firewallSetup() {
	while true; do
		read -p "IP to allow from: " allowed_ip
		read -p "Port to allow to: " allowed_port
		sudo ufw allow from $allowed_ip to any port $allowed_port comment "Allow $allowed_ip to port $allowed_port"
		read -p "Add another? (y/n) " choice
		case $choice in
			[Yy]* ) continue;;
			[Nn]* ) break;;
			* ) echo "You must answer (y/n)."
		esac
	done
}
#
# If the ufw package is installed, ask the user if they'd like to modify the firewall rules and enable it.
#
if ls /usr/sbin/ | grep "ufw"; then
	if ask_yes_no ":: Modify firewall?"; then
		firewallSetup
	else
		echo "Skipping."
	fi
else
	echo "UFW install not detected, skipping firewall setup."
fi

if ls /usr/sbin/ | grep "ufw"; then
	if ask_yes_no ":: Enable firewall?"; then
		sudo ufw enable
	else
		echo "Skipping."
	fi
else
	echo "..."
fi

if ask_yes_no ":: Clone nvim configuration from git?"; then
	git clone https://github.com/nakouchdoge/nvim /home/$USER/.config/nvim
	echo "Git repository nakouchdoge/nvim has been cloned"
else
	echo "Skipping."
fi

echo "****END OF SCRIPT**** Log out and log back in for changes to take effect."
exit
