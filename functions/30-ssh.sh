#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

function sshKeySetup {
	while true; do
		read -p "${purple}Input SSH key (one at a time): ${cr}" user_ssh_key
		echo "$user_ssh_key" >> /home/$USER/.ssh/authorized_keys
		read -p "${purple}Add another? (y/n): ${cr}" choice
		case $choice in
			[Yy]* ) continue;;
			[Nn]* ) break;;
			* ) echo "${red}You must answer (y/n)${cr}"
		esac
	done
}

function sshAuthorizedKeys {
	if [ ! -d "/home/$USER/.ssh" ]; then
		touch /home/$USER/.ssh
	else
		:	
	fi
	if ask_yes_no "${purple}:: Modify authorized SSH keys? This will create a backup of ~/.ssh/authorized_keys and create a new one. ${cr}"; then
		echo "${purple}Creating ~/.ssh/authorized_keys${cr}"
		if [ -f "/home/$USER/.ssh/authorized_keys" ]; then
			cp /home/$USER/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys.old
			echo "${green}Copied authorized_keys file to authorized_keys.old${cr}"
		else
			echo "${green}Creating authorized_keys file${cr}"
			touch /home/$USER/.ssh/authorized_keys
		fi
		export usergroupID=$(grep "$USER" "/etc/passwd" | grep -oP "[0-9]+:[0-9]+")
		sudo chown -R $usergroupID /home/$USER/.ssh
		if [ -O "/home/$USER/.ssh" ]; then
			echo "${green}Success${cr}"
		else
			echo "${red}Check permissions of /home/$USER/.ssh directory.${cr}"
		fi
		if ask_yes_no "${purple}:: Input SSH keys? (At least one is required for key authentication!) ${cr}"; then
			sshKeySetup
		else
			skipping
		fi
	else
		skipping
	fi
}
#
# Ask user if they want to modify the default SSH port.
#
function sshPortChange {
	if ask_yes_no "${purple}:: Change SSH port? ${cr}"; then
		read -p "${purple}Port to use for SSH: ${cr}" ssh_port
		echo "${green}Changing default SSH port to $ssh_port.${cr}"
		if [ -f "/etc/ssh/sshd_config" ]; then
			sudo sed -i "s/.*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
			echo "${green}Success${cr}"
		else
			echo "${red}/etc/ssh/sshd_config does not exist. Something went wrong.${cr}"
		fi
	else
		skipping
	fi
}
#
# Add standard SSH security settings
#
function echoSshSecurity {
	sudo touch /etc/ssh/sshd_config.d/10-security.conf
	sudo echo "#Override for any other .conf files that may appear here to ensure password authentication and root login is prohibited" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "PermitEmptyPasswords no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "PubkeyAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "ChallengeResponseAuthentication no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
	sudo echo "UsePAM no" | sudo tee /etc/ssh/sshd_config.d/10-security.conf -a
}

function sshSecurity {
	if ask_yes_no "${purple}:: Change SSH security config? ${cr}"; then
		echo "${green}Securing SSH for key-based authentication and removing root login.${cr}"
		if [ -f "/etc/ssh/sshd_config.d/10-security.conf" ]; then
			sudo mv /etc/ssh/sshd_config.d/10-security.conf /etc/ssh/sshd_config.d/10-security.conf.old
			echoSshSecurity
			echo "${green}Backed up old 10-security.conf (10-security.conf.old) file and created a new one default rules${cr}"
		else
			echoSshSecurity
			echo "${green}Created 10-security.conf file with default rules${cr}"
		fi
	else
		skipping
	fi
}

function sshService {
	if ask_yes_no "${purple}:: Restart sshd.service? If you changed the security config, you should answer yes. ${cr}"; then
		echo "${purple}Restarting sshd.service${cr}"
		sudo systemctl restart sshd
		sleep 3
		echo "${green}Restarted sshd.service${cr}"
	else
		skipping
	fi
}
