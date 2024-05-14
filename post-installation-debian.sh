#!/bin/bash
#
# --- Version 0.1 ---
# 
# This is TN. github@nakouchdoge/scripts
#
DIR="$(dirname "$0")"

. "$DIR"/functions/base.sh
. "$DIR"/functions/00-misc.sh
. "$DIR"/functions/10-packages.sh
. "$DIR"/functions/20-bash.sh
. "$DIR"/functions/30-ssh.sh
. "$DIR"/functions/40-firewall.sh

red=$'\e[31m'
purple=$'\e[35m'
green=$'\e[32m'
grey=$'\e[90m'
cr=$'\e[0m'

welcomeMessage

changeHostname

installDocker

installPackages

detectPackagesInstalled

bashPrompt
bashTimeout

sshAuthorizedKeys

sshPortChange

sshSecurity

sshService

detectUfw
enableUfw

nvimConfig

echo "::"
echo "${red}****END OF SCRIPT****${cr} Log out and log back in for changes to take effect."
echo "::"

exit
