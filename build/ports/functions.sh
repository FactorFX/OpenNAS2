#!/usr/bin/env bash

############################################################ GLOBALS

PORT_FREEBSD_VERSION="$RELEASE_VERSION-${BRANCH^^}"

## POUDRIERE CONF ##
PORT_BASEFS="$WORK_PATH/poudriere"

PORT_DISTFILES_CACHE="$PORT_BASEFS/distfiles"
PORT_D_PATH="$PORT_BASEFS/poudriere.d"
PORT_PORTS_DIR="$PORT_BASEFS/ports/$PROJECT_NAME"
PORT_OPTIONS_DIR="$PORT_D_PATH/$PROJECT_NAME-options"

PORT_CONF_ORIG="$ROOT_DIR/build/$current_domain/conf/poudriere.conf"
PORT_CONF_DEST="$PORT_BASEFS/poudriere.conf"

## PORTS VARIABLES ##
PORT_EXTRA_DIR="$ROOT_DIR/build/ports/extras"

PORT_LIST="$PORT_D_PATH/$PROJECT_NAME-ports"
PORT_EXTRA_PARAM="-e $PORT_BASEFS"
PORT_PKG_REPO="$PORT_BASEFS/data/packages/$PROJECT_NAME-$PROJECT_NAME"
PORT_PKG_NAME="$PROJECT_NAME:${PROJECT_VERSION%.*}:${TARGET_ARCH}"
PORT_PKG_REPO_PATH_TEMP="$PROJECT_PATH/repos/$PORT_PKG_NAME"
PORT_JAIL="$PORT_D_PATH/jails/$PROJECT_NAME"

PORT_OPTIONS_TABLE="$ROOT_DIR/build/ports/port_options_table.sh"

PORT_NCPU=$(sysctl -n hw.ncpu)
if [ $PORT_NCPU -gt $MAX_PARALLEL_PJOBS ]; then
	PORT_NCPU=$MAX_PARALLEL_PJOBS
fi

############################################################ FUNCTIONS

port_poudriere_command()
{
	local command="$1"
	local step run
	
	case "$command" in
		delete|create|update)
			;;
		*)
			die
			;;
	esac
	step="${command^^} POUDRIERE PORTS"
	# Substitute the first caracter to get the action
	run="poudriere $PORT_EXTRA_PARAM ports -${command:0:1} -q -p $PROJECT_NAME"
	log_command "$current_domain" "$step" "$run" || die
}

# Check if port exist in poudriere
port_check_exist()
{	
	local COMMAND="$(poudriere $PORT_EXTRA_PARAM ports -l | awk 'var {print $1}' var=$PROJECT_NAME )"
	
	if [ -n "$COMMAND" ]; then
		return $SUCCESS
	else
		return $FAILURE
	fi
}

port_cleanup()
{
	if [ -d "$PORT_OPTIONS_DIR" ]; then
		rm -rf $PORT_OPTIONS_DIR
	fi
}

############################################################ MAIN

trap "port_cleanup" 	EXIT
