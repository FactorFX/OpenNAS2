#!/bin/sh

############################################################ FUNCTIONS

check_bash()
{
	local COMMAND FOUND
	
	FOUND=$(command -v bash || echo '')
	
	COMMAND="pkg install bash"

	if [ -z "$FOUND" ]; then
		echo "ERROR: Please install bash, with '$COMMAND' command."
		read -p "Do you want I install it for you? [y/N] : " yn
		case $yn in
			[Yy]* ) exec $COMMAND; break;;
			* ) exit 1;;
		esac
	fi
}

############################################################ MAIN

check_bash
