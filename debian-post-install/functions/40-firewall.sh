#!/bin/bash

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

function firewallSetup {
	while true; do
		read -p "${purple}IP to allow from: ${cr}" allowed_ip
		read -p "${purple}Port to allow to: ${cr}" allowed_port
		sudo ufw allow from $allowed_ip to any port $allowed_port comment "Allow $allowed_ip to port $allowed_port"
		read -p "${purple}Add another? (y/n) ${cr}" choice
		case $choice in
			[Yy]* ) continue;;
			[Nn]* ) break;;
			* ) echo "${red}You must answer (y/n).${cr}"
		esac
	done
}

function detectUfw {
	if ls /usr/sbin/ | grep "ufw"; then
		if ask_yes_no "${purple}:: Modify firewall? ${cr}"; then
			firewallSetup
		else
			echo "${grey}Skipping.${cr}"
		fi
	else
		echo "${grey}UFW install not detected, skipping firewall setup.${cr}"
	fi
}

function enableUfw {
	if ls /usr/sbin/ | grep "ufw"; then
		if ask_yes_no "${purple}:: Enable firewall? ${cr}"; then
			sudo ufw enable
		else
			echo "${grey}Skipping.${cr}"
		fi
	else
		echo "..."
	fi
}
