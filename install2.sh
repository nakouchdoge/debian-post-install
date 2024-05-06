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
if ask_yes_no "Change hostname?"; then
	read -p "Enter new hostname: " new_hostname
	sudo hostnamectl hostname $new_hostname
else
	echo "Skipping."
fi
#
# Ask the user if they'd like to install docker. First we update the system, get the keyring for docker, add the
# repository, and install the packages through apt.
#
if ask_yes_no "Install docker?"; then
	echo "Installing docker engine"

	sudo apt-get update
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
	echo "Adding $USER to docker group. Restart to the session for changes to apply."

	sudo usermod -aG docker $USER
else
	echo "Skipping docker installation."
fi
#
# User chosen or default basic packages.
#
if ask_yes_no "Install packages?"; then
	if ask_yes_no "Install default packages?\n(ncdu, htop, ufw, qemu-guest-agent, nvim, vim, fzf)?"; then
		echo "Installing default pacakges."
		sudo apt update && sudo apt upgrade -y
		sudo apt install ncdu htop ufw qemu-guest-agent neovim vim fzf -y
		echo "Enabling qemu-guest-agent."
		sudo systemctl enable --now qemu-guest-agent.service
	else
		read -p "Type the packaged you would like installed (separated by a single space): " packages_to_install
		echo "installing $packages_to_install."
		sudo apt install $packages_to_isntall -y
		if sudo apt list --installed | grep -qF "qemu-guest-agent"; then
			sudo systemctl enable --now qemu-guest-agent.service
		else
			:
		fi
	fi
else
	echo "No packages chosen for install, updating & upgrading system."
	sudo apt update && sudo apt upgrade -y
fi
# *TESTING*
#
# Ask to install the custom bash prompt. This is a "debian red" prompt.
#
if ask_yes_no "Add custom red bash prompt?"; then
	echo "Adding custom red bash prompt."

	if [ -f "/home/$USER/.bashrc" ]; then
		cp /home/$USER/.bashrc /home/$USER/.bashrc.old
		if grep -qF "#CUSTOM_BASH_PROMPT" "/home/$USER/.bashrc"; then
			echo "bash prompt already exists"
		else
			echo "#CUSTOM_BASH_PROMPT" >> /home/$USER/.bashrc
			echo "PS1='\[\e[91m\]\u@\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bashrc
		fi
	else
		echo ".bashrc does not exist. Something went wrong."
	fi
else
	echo "Keeping default bash prompt."
fi
#
# Ask the user if they'd like to add an automatic session timeout in a user defined number of seconds.
#
if ask_yes_no "Set a console timeout?"; then
	read -p "Enter timeout in seconds: " tmout_seconds
	if [ -f "/home/$USER/.bashrc" ]; then
		if grep -qF "TMOUT=$tmout_seconds" "/home/$USER/.bashrc"; then
			echo "TMOUT=$tmout_seconds already exists in ~/.bashrc. Skipping."
		elif grep -qF "TMOUT=" "/home/$USER/.bashrc"; then
			echo "Some timeout (TMOUT=) line already exists in ~/.bashrc. Skipping."
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
if ask_yes_no "Modify SSH keys? This will create a backup of ~/.ssh/authorized_keys and create a new one."; then
	echo "Creating ~/.ssh/authorized_keys"
	if [ -f "/home/$USER/.ssh/authorized_keys" ]; then
		mv /home/$USER/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys.old
		echo "Moved old authorized_keys file to authorized_keys.old"
	else
		echo "Creating authorized_keys file"
	fi
	touch /home/$USER/.ssh/authorized_keys
	sudo chown -R $USER /home/$USER/.ssh
	ask_yes_no "Input SSH keys? (At least one is required for key authentication!) :"
	ssh_key_setup
else
	echo "Skipping."
fi
#
# Ask user if they want to modify the default SSH port.
#
if ask_yes_no "Change SSH port?"; then
	read -p "Port to use for SSH: " ssh_port
	echo "Changing default SSH port to $ssh_port."
	if [ -f "/etc/ssh/sshd_config" ]; then
#		sudo sed -i 's/#Port 22/Port $ssh_port/' /etc/ssh/sshd_config
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
if ask_yes_no "Change SSH security config?"; then
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

if ask_yes_no "Restart sshd.service? If you changed the security config, you should answer yes."; then
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
	if ask_yes_no "Modify firewall?"; then
		firewallSetup
	else
		echo "Skipping."
	fi
else
	echo "UFW install not detected, skipping firewall setup."
fi

if ls /usr/sbin/ | grep "ufw"; then
	if ask_yes_no "Enable firewall?"; then
		sudo ufw enable
	else
		echo "Skipping."
	fi
else
	echo "..."
fi

echo "****END OF SCRIPT****"

exit
