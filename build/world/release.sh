#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/world/functions.sh

############################################################ FUNCTIONS

world_release()
{
	local step run
	
	step="BUILD WORLD"
	run="chroot $WORLD_PATH make -C /usr/src $WORLD_MAKE_FLAGS buildworld $WORLD_CLEAN"
	log_command "$current_domain" "$step" "$run" || die
	
	step="BUILD KERNEL"
	run="chroot $WORLD_PATH make -C /usr/src $KERNEL_MAKE_FLAGS $WORLD_KERNEL_DEPEND buildkernel $WORLD_KERNELCLEAN"
	log_command "$current_domain" "$step" "$run" || die
}

############################################################ MAIN

world_init
world_set_clean
world_release

remove_clean_flag "world"
