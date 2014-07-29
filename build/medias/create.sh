#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/world/functions.sh
include $ROOT_DIR/build/ports/functions.sh
include $ROOT_DIR/build/medias/functions.sh

############################################################ FUNCTIONS

media_create()
{	
	local step run

	step="CREATE MEDIAS"
	run="chroot $WORLD_PATH env $RELEASE_FLAGS $MEDIAS_RELEASE_SCRIPT_DEST/release.sh \
		-m iso -m img -m ftp \
		$PROJECT_NAME \
		$PORT_PKG_REPO_PATH_TEMP \
		$MEDIAS_INSTALL_PKG_CONF \
		$MEDIAS_OUTPUT_DIR \
		$RELEASE_MAKE_FLAGS"
	log_command "$current_domain" "$step" "$run"
}

############################################################ MAIN

world_init
media_init
media_create
media_move

