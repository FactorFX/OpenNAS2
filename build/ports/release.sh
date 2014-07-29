#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/ports/functions.sh

############################################################ FUNCTIONS

port_build()
{
	local step run
	local clean_port='-C'
	local retval
	
	if check_clean_flag "port"; then
		clean_port='-c'
	fi
	
	step="BUILD PORTS, it takes a while..."
	run="$ENV_SETUP poudriere $PORT_EXTRA_PARAM bulk $clean_port -f $PORT_LIST -j $PROJECT_NAME -p $PROJECT_NAME"
	log_command "$current_domain" "$step" "$run" || die
	retval=$?
	
	# If poudriere bulk is ok delete the clean world flag
	[ $retval -eq 0 ] && remove_clean_flag "port"
}

############################################################ MAIN

port_build
