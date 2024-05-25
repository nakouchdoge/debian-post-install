#!/bin/bash
#
# Declare files with functions
#

DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh

function addBashPrompt {
	echo "PS1='\[\e[91m\]\u@\h\[\e[0m\]:\[\e[38;5;38m\]\w\[\e[0m\]\$ '" >> /home/$USER/.bash_prompt
	if grep -qF "source /home/$USER/.bash_prompt" "/home/$USER/.bashrc"; then
		echo "${green}Custom prompt source file exists in ~/.bashrc. ~/.bashrc has not been modified.${cr}"
	else
		echo "source /home/$USER/.bash_prompt" >> /home/$USER/.bashrc
		echo "${green}Added source line to .bashrc${cr}"
	fi
}

function bashPrompt {
	if ask_yes_no "${purple}:: Add custom debian bash prompt? ${cr}"; then
			if [ -f "/home/$USER/.bashrc" ]; then
			if [ -f "/home/$USER/.bash_prompt" ]; then
				mv /home/$USER/.bash_prompt /home/$USER/.bash_prompt.bak
				echo "${green}.bash_prompt backed up to .bash_prompt.bak${cr}"
				addBashPrompt
			else
				touch /home/$USER/.bash_prompt
				echo "${green}Created ~/.bash_prompt${cr}"
				addBashPrompt
			fi
		else
			echo "${red}~/.bashrc does not exist! Something went wrong.${cr}"
		fi
	else
		skipping
	fi
}

function checkBashCustom {
	if [ -f "/home/$USER/.bash_custom" ]; then
		if ask_yes_no "${red}/home/$USER/.bash_custom already exists. Backup and create new file?${cr}"; then
			mv /home/$USER/.bash_custom /home/$USER/.bash_custom.bak
			touch /home/$USER/.bash_custom	
			if [ -f "/home/$USER/.bash_custom" ]; then
				success
			else
				skipping
			fi
		else
			skipping
		fi
	else
		touch /home/$USER/.bash_custom
			if [ -f "/home/$USER/.bash_custom" ]; then
				success
			else
				echo "${red}Something went wrong. Check /home/$USER directory/${cr}"
			fi
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
					skipping
				fi
			else
				echo "TMOUT=$tmout_seconds" >> /home/$USER/.bashrc
				echo "${green}A $tmout_seconds second timeout has been added and will be applied on next login or by running a new shell.${cr}"
			fi
		else
				echo "${red}.bashrc does not exist. Something went wrong.${cr}"
		fi
	else
		skipping
	fi
}
