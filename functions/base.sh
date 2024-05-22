#!/bin/bash

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

scriptversion="0.2.2"

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

function skipping {
	echo "${grey}Skipping.${cr}"
}

function success {
	echo "${green}Success.${cr}"
}
