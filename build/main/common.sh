#!/usr/bin/env bash

############################################################ CHECK

: ${PROJECT_NAME:?PROJECT_NAME is not defined!}
: ${BUILD_DATE:?BUILD_DATE is not defined!}
: ${BUILD_TIME:?BUILD_TIME is not defined!}
: ${PROJECT_VERSION:?PROJECT_VERSION is not defined!}

############################################################ GLOBALS

[ "x$DEBUG" != "x" ] && set -x && set -e

#
# Global exit status variables
#
SUCCESS=0
FAILURE=1

current_domain=$(basename "${0%/*}")

: ${TARGET_ARCH=$(uname -p)}
if ! [ "${TARGET_ARCH}" == "amd64" ] ; then
	echo "You can only compile on amd64 system!"
	die
fi

ARCH_FLAGS=
if [ -n "$TARGET" ] && [ -n "$TARGET_ARCH" ]; then
	ARCH_FLAGS="TARGET=$TARGET TARGET_ARCH=$TARGET_ARCH"
fi

BUILD_OUT_DIR="$ROOT_DIR/out"
RELEASE_VERSION="10.0"
BRANCH="releng"

## WORK CONF ##
WORK_PATH="$ROOT_DIR/work"

## REQUIRED ##
declare -A REQUIRED_PKG
REQUIRED_PKG[git]="devel/git"
REQUIRED_PKG[poudriere]="ports-mgmt/poudriere-devel"

## LOG ##
LOG_DIR="$ROOT_DIR/logs"
LAST_LOG="$LOG_DIR/last.log"

## PROJECT PATH ##
PROJECT_PATH="/usr/local/$PROJECT_NAME"

## MAXIMUX PARALLEL JOB FOR POUDRIERE ##
MAX_PARALLEL_PJOBS=5

############################################################ FUNCTIONS

cp_last_log()
{
	if [ "$log_file" != "" ] && [ -s "$LAST_LOG" ] && [ -f "$log_file" ]; then
		cat "$LAST_LOG" >> "$log_file"
		cat /dev/null > "$LAST_LOG"
	fi
}

die()
{
	local status=$FAILURE

	# If there is at least one argument, take it as the status
	if [ $# -gt 0 ]; then
		status=$1
		shift 1 # status
	fi

	exit $status
}

include()
{
	local file="$1"
	. "$file" || exit $?
}

join_array()
{
	local ret
	local sep 
	local array

	sep="$1 "
	shift
	ret=$(printf "${sep}%s" "$@")
	echo "${ret:${#sep}}"
}

parse_pkg()
{
	local pkg="$1"
	local find="$2"
	local parse
	
	parse="$(pkg info "$pkg" | grep "$find" | awk '/:/ {print $3}')"
	
	echo "$parse"
}

log_command()
{
	[ "$#" -ge 3 ] || die;

	local domain="$1"
	local comment="$2"
	local command="$3"
	local display="$4"
	local advert retval

	log_file="$LOG_DIR/${BUILD_DATE}_${BUILD_TIME}/$domain.log"
	
	# Create dirpath name of LOG_FILE
	mkdir -p "${log_file%/*}"
	
	touch "$log_file"
	
	cat /dev/null > "$LAST_LOG"
	
	if [ -n "$comment" ]; then
		[ "$DEBUG" ] && set +x
		advert="$(log_advert "$comment" "$command")"
		echo "$advert" >> "$LAST_LOG"
		[ "$DEBUG" ] && set -x
	fi
	
	# Don't display $comment only if $display equal false
	[ "$display" = false ] || echo "$comment"
	
	eval "$command" >> $LAST_LOG 2>&1
	retval=$?
	
	cp_last_log

	return $retval
}

log_advert()
{
	[ "$#" -ne 2 ] && die;
	
	local comment="$1"
	local command="$2"
	local SEP
	
	SEP="***********************************************************"
	
	printf "%s\n** %s at %s\n%s\nCommand: %s\n" "$SEP" "$comment" "$(date +%H:%M:%S)" "$SEP" "$command"
}

create_clean_flag()
{
	[ "$#" -ne 1 ] && die;
	
	local flags="$1"
	
	for flag in $flags; do
		touch "$WORK_PATH/.${flag}_clean"
	done
}

remove_clean_flag()
{
	[ "$#" -ne 1 ] && die;
	
	local flags="$1"
	
	for flag in $flags; do
		if [ -f "$WORK_PATH/.${flag}_clean" ]; then
			rm "$WORK_PATH/.${flag}_clean"
		fi
	done
}

check_clean_flag()
{
	[ "$#" -ne 1 ] && die;
	
	local flag="$1"
	
	if [ -f "$WORK_PATH/.${flag}_clean" ]; then
		return $SUCCESS
	else
		return $FAILURE
	fi
}

dirempty()
{
	[ "$#" -ne 1 ] && die;
	
	local dir="$1"
	
	[ "$(ls -A $dir)" ] && return $SUCCESS || return $FAILURE
}

############################################################ MAIN

#
# Trap signals so we can recover gracefully
#
trap 'die'	SIGINT SIGTERM SIGPIPE SIGXCPU SIGXFSZ \
			SIGFPE SIGTRAP SIGABRT SIGSEGV \
			SIGALRM SIGPROF SIGUSR1 SIGUSR2 SIGHUP SIGVTALRM
trap 'cp_last_log' EXIT
