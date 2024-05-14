#!/bin/bash

function ask_yes_no {
	local red=$'\e[31m'
	cr=$'\e[0m'
	while true; do
		read -p "$1 (y/n): " yn
		case $yn in
			[Yy]* ) return 0;;
			[Nn]* ) return 1;;
			* ) echo "${red}Invalid response${cr}";;
		esac
	done
}
