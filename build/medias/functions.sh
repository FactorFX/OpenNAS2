#!/usr/bin/env bash

############################################################ GLOBALS

MEDIAS_RELEASE_SCRIPT_ORIG="$ROOT_DIR/build/medias/scripts"
MEDIAS_RELEASE_SCRIPT_DEST="$PROJECT_PATH/scripts"

MEDIAS_RCLOCAL_CONF="rc.local"

MEDIAS_OUTPUT_DIR="/tmp/out"

RELEASE_FLAGS="$ARCH_FLAGS PORT_PKG_NAME=$PORT_PKG_NAME"

############################################################ FUNCTIONS

media_init()
{
	rm -rf $WORLD_PATH$PORT_PKG_REPO_PATH_TEMP
	
	mkdir -p $WORLD_PATH$MEDIAS_RELEASE_SCRIPT_DEST $WORLD_PATH$PORT_PKG_REPO_PATH_TEMP $BUILD_OUT_DIR
	
	cp -R $MEDIAS_RELEASE_SCRIPT_ORIG/* $WORLD_PATH$MEDIAS_RELEASE_SCRIPT_DEST
	
	mount -t nullfs $PORT_PKG_REPO $WORLD_PATH$PORT_PKG_REPO_PATH_TEMP
}

media_move()
{
	local out_dir
	
	out_dir="$WORLD_PATH$MEDIAS_OUTPUT_DIR"
	
	if [ -d "$out_dir" ]; then
		echo "MOVE MEDIAS"
		cp -R $out_dir/ $BUILD_OUT_DIR/
		rm -rf $out_dir
	fi
}

media_cleanup()
{
	umount $WORLD_PATH$PORT_PKG_REPO_PATH_TEMP
}

############################################################ MAIN

trap "media_cleanup" EXIT
