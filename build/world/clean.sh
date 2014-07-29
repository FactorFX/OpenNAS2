#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/world/functions.sh

############################################################ FUNCTIONS

clean()
{	
	[ ! -d "$WORLD_PATH" -o ! -d "$WORLD_SRC_PATH" ] && exit $SUCCESS
	
	echo "Cleanup the $WORLD_PATH directory"
	# Revert svn chroot/usr/src
	world_svn_cleanup $WORLD_SRC_PATH || exit $SUCCESS
	
	# Mount devfs in chroot
	world_mount_dev
	# Do make clean in chroot
	eval chroot $WORLD_PATH make -C /usr/src clean > /dev/null
	# Cleanup chroot
	make -C $WORLD_SRC_PATH clean > /dev/null
}

############################################################ MAIN

clean

# Create a clean trace
create_clean_flag "world port"
