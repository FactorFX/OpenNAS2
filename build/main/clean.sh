#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1

############################################################ FUNCTIONS

clean()
{	
	set +e
	
	# Parameter must be provided
	[ "$#" -ne 1 ] && die;
	
	local DIR="$1"

	echo "Remove dir $1"
	chflags -R 0 "$1"
	rm -rf "$1"
	
	exit $SUCCESS
}

############################################################ MAIN

clean "$@" 2>/dev/null
