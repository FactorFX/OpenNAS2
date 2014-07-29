#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1

############################################################ FUNCTIONS

check_for_require_pkgs()
{
	local FOUND REQUIRED_COMMAND_LIST PKG_RUN_COMMAND NB_PKG

	for COMMAND in ${!REQUIRED_PKG[@]}; do
		FOUND="$(parse_pkg ${REQUIRED_PKG[$COMMAND]} Origin)"
		[ "$FOUND" = "${REQUIRED_PKG[$COMMAND]}" ] && unset REQUIRED_PKG[$COMMAND]
	done

	REQUIRED_COMMAND_LIST="$(join_array , ${!REQUIRED_PKG[@]})"
	PKG_RUN_COMMAND="pkg install ${REQUIRED_PKG[@]}"
	NB_PKG=${#REQUIRED_PKG[@]}

	if (( $NB_PKG > 0 )); then
		echo "ERROR: You must install $REQUIRED_COMMAND_LIST by running '$PKG_RUN_COMMAND' command."
		read -p "Do you want I install th(is/em) for you? [y/N] : " yn
		case $yn in
			[Yy]* ) exec $PKG_RUN_COMMAND; break;;
			* ) die;;
		esac
	fi
}

############################################################ MAIN

check_for_require_pkgs

echo -e "You can follow log with the file $LAST_LOG\n"
