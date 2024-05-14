#!/bin/bash
#
# Declare files with functions
#

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

function bashPrompt {
	if ask_yes_no "${purple}:: Add custom debian bash prompt? ${cr}"; then
		if [ -f "/home/$USER/.bashrc" ]; then
			if [ -f "/home/$USER/.bash_prompt" ]; then
				mv /home/$USER/.bash_prompt /home/$USER/.bash_prompt.bak
				echo "PS1='\[\e[91m\]\u@\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bash_prompt
				echo "${green}.bash_prompt backed up and custom prompt added${cr}"
				if grep -qF "source /home/$USER/.bash_prompt" "/home/$USER/.bashrc"; then
					echo "${green}Custom prompt source file exists in ~/.bashrc. ~/.bashrc has not been modified.${cr}"
				else
					echo "source /home/$USER/.bash_prompt" >> /home/$USER/.bashrc
					echo "${green}Added source line to .bashrc${cr}"
				fi
			else
				touch /home/$USER/.bash_prompt
				echo "PS1='\[\e[91m\]\u@\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bash_prompt
				echo "${green}Created ~/.bash_prompt${cr}"
				if grep -qF "source /home/$USER/.bash_prompt" "/home/$USER/.bashrc"; then
					echo "${green}Custom prompt source file exists in ~/.bashrc. ~/.bashrc has not been modified.${cr}"
				else
					echo "source /home/$USER/.bash_prompt" >> /home/$USER/.bashrc
					echo "${green}Added source line to .bashrc${cr}"
				fi
			fi
		else
			echo "${red}~/.bashrc does not exist! Something went wrong.${cr}"
		fi
	else
		echo "${grey}Skipping.${cr}"
	fi
}

function bashTimeout {
	if ask_yes_no "${purple}:: Set a console timeout? ${cr}"; then
		read -p "${purple}Enter timeout in seconds: ${cr}" tmout_seconds
		if [ -f "/home/$USER/.bashrc" ]; then
			if grep -qF "TMOUT=$tmout_seconds" "/home/$USER/.bashrc"; then
				echo "${grey}TMOUT=$tmout_seconds already exists in ~/.bashrc. Skipping.${cr}"
			elif grep -qF "TMOUT=" "/home/$USER/.bashrc"; then
				if ask_yes_no "${red}:: A timeout already exists in ~/.bashrc. Overwrite? ${cr}"; then
					sed -i "s/TMOUT.*/TMOUT=$tmout_seconds/" ~/.bashrc
					echo "${green}A $tmout_seconds second timeout has been added and will be applied on next login or by running a new shell.${cr}"
				else
					echo "${grey}Skipping.${cr}"
				fi
			else
				echo "TMOUT=$tmout_seconds" >> /home/$USER/.bashrc
				echo "${green}A $tmout_seconds second timeout has been added and will be applied on next login or by running a new shell.${cr}"
			fi
		else
				echo "${red}.bashrc does not exist. Something went wrong.${cr}"
		fi
	else
		echo "${grey}Skipping.${cr}"
	fi
}
