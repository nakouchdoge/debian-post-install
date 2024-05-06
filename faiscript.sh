#!/bin/bash

# This script is meant to be used in a FAI (fully automated install) or any other custom debian ISO.
# Made by and for TN.
#
# ---
# Verify networking.service is enabled and running to make sure a DHCP address has been assigned
#
# Check for and wait for the DHCP address to be assigned, disregard localhost IP.

check_ip_assigned() {
	ip a | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.'
}

while true; do
	if check_ip_assigned; then
		echo "IP address found."
		break
	else
		echo "No IP address found. Sleeping for 10 seconds..."
		sleep 10
	fi
done
#
# Install all the packages from the new repository. Included docker-compose package.
#
# Install default packages
#
sudo apt update && sudo apt upgrade -y

echo "Installing default packages."

sudo apt-get install qemu-guest-agent vim ufw htop ncdu unattended-upgrades -y

echo "Enabling qemu-guest-agent."

sudo systemctl enable --now qemu-guest-agent.service
#
# Install "debian red" prompt.
#
echo "Adding custom red bash prompt."

if [ -f "/home/tn/.bashrc" ]; then
	cp /home/tn/.bashrc /home/tn/.bashrc.old
	if grep -qF "#CUSTOM_BASH_PROMPT" "/home/tn/.bashrc"; then
		echo "bash prompt already exists"
	else
		echo "#CUSTOM_BASH_PROMPT" >> /home/tn/.bashrc
		echo "PS1='\[\e[91m\]\u@\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/tn/.bashrc
	fi
else
	echo ".bashrc does not exist. Something went wrong."
fi
#
# Add a 600 second timeout to the session (for security)
#
if [ -f "/home/tn/.bashrc" ]; then
	if grep -qF "TMOUT=600" "/home/tn/.bashrc"; then
		echo "TMOUT=600 already exists in ~/.bashrc"
	else
		echo "TMOUT=600" >> /home/tn/.bashrc
	fi
else
        echo ".bashrc does not exist. Something went wrong."
fi
#
# Create and configure SSH keys.
#
echo "Creating SSH directory."

if [ -d "/home/tn/.ssh" ]; then
	echo ".ssh directory exists, skipping"
else
	echo "Creating /home/tn/.ssh directory"
	mkdir "/home/tn/.ssh"
	sudo chown -R tn /home/tn/.ssh
fi
#
# Backup any authorized_keys file that may exist and create a new one with all of my SSH host's keys.
#
echo "Creating ~/.ssh/authorized_keys"

if [ -f "/home/tn/.ssh/authorized_keys" ]; then
	mv /home/tn/.ssh/authorized_keys /home/tn/.ssh/authorized_keys.old
	echo "Moved old authorized_keys file to authorized_keys.old"
else
	echo "Creating authorized_keys file"
fi

touch /home/tn/.ssh/authorized_keys
sudo chown -R tn /home/tn/.ssh

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSSzG1+3CTQy6Wf9u1ixRA732cBHqHUWs3j72dnFlHi tn@PouchCC" >> /home/tn/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKE2rEe5mURLZZfR9BB4dkLJzpqL89fnTIO9KUQbFmcm tn@macbook-m3.local" >> /home/tn/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVRLnR0+Du8MZqblLXjI63aVg50AHGsFuSJaqJE+KnH tn@new-ansible" >> /home/tn/.ssh/authorized_keys
#
# Change default SSH port to 737.
#
echo "Changing default SSH port to 737."

if [ -f "/etc/ssh/sshd_config" ]; then
	sudo sed -i 's/#Port 22/Port 737/' /etc/ssh/sshd_config
	echo "SSH changed to port 737"
else
	echo "/etc/ssh/sshd_config does not exist. Something went wrong."
fi
#
# Add standard SSH security settings
#
echo "Securing SSH."

if [ -f "/etc/ssh/sshd_config.d/10-security.conf" ]; then
	sudo mv /etc/ssh/sshd_config.d/10-security.conf /etc/ssh/sshd_config.d/10-security.conf.old
	sudo touch /etc/ssh/sshd_config.d/10-security.conf
	sudo cat << EOF > /etc/ssh/sshd_config.d/10-security.conf
#Override for any other .conf files that may appear here to ensure password authentication and root login is prohibited
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
Port 737
EOF
	echo "Backed up old 10-security.conf file and created a new one with rules"
	else
	sudo touch /etc/ssh/sshd_config.d/10-security.conf
	sudo cat << EOF > /etc/ssh/sshd_config.d/10-security.conf
#Override for any other .conf files that may appear here to ensure password authentication and root login is prohibited
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
Port 737
EOF
	echo "Created 10-security.conf file and added rules"
fi

echo "Restarting sshd.service"

sudo systemctl restart sshd
#
# Add firewall rules for SSH hosts and enable the firewall.
#
echo "Modifying firewall rules"
#Define ip address from grepping "ip a" command
#ip_address=$(ip a | grep inet | grep -v 'inet6' | grep -v '/8' | grep -v '/16' | awk '{print $2}' | cut -d'/' -f1)

#not including ip_address variable in commands. If the system is given a new static IP, just run the post-install.sh script to fix the "to any" part of the ufw table
sudo ufw allow from 10.1.10.69 to any port 737 comment "Allow PouchCC to 737"
sudo ufw allow from 10.1.30.99 to any port 737 comment "Allow ansible to 737"
sudo ufw allow from 172.16.69.5 to any port 737 comment "Allow Macbook WG to 737"
sudo ufw allow from 172.16.69.2 to any port 737 comment "Allow iPhone WG to 737"
sudo ufw allow from 172.16.69.4 to any port 737 comment "Allow PouchCC WG to 737"

sudo ufw enable

git clone https://github.com/nakouchdoge/post-install-debian.git /home/tn/post-install-debian

echo "****END OF SCRIPT****"

exit
