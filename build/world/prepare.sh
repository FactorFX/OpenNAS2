#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/world/functions.sh

############################################################ FUNCTIONS

world_prepare()
{
	local CONF_FILES STEP 

	# Check if directory doesn't exist or not a svn repo
	if ! world_svn_ok "$WORLD_SRC_PATH"; then
		world_svn_create "$WORLD_SRC_PATH" "$WORLD_SVN_URL"
	# Check if we can revert the svn repo and can update it
	elif ! world_svn_cleanup "$WORLD_SRC_PATH" || ! world_svn_update "$WORLD_SRC_PATH"; then		
		world_svn_create "$WORLD_SRC_PATH" "$WORLD_SVN_URL"
	fi
}

world_custom_src()
{
	local FILES DIR GENERAL_FILE PROJECT_FILE INSERT
	
	# Get all patch files
	# If same file exist in general and project directories, only project patch file is get
	FILES=''
	DIR="$WORLD_CUSTOM_SRC_DIR/$PROJECT_NAME"
	if [ -d "$DIR" ]; then
		FILES="$(find $DIR -type f -name "*.patch")"
	fi

	DIR="$WORLD_CUSTOM_SRC_DIR/$WORLD_GENERAL_CUSTOM_DIR"
	if [ -d "$DIR" ]; then
		for GENERAL_FILE in $(find $DIR -type f -name "*.patch"); do
			INSERT=true
			for PROJECT_FILE in ${FILES[@]}; do
				if [ "${GENERAL_FILE##*/}" == "${PROJECT_FILE##*/}" ]; then
					INSERT=false
					break
				fi
			done
			
			if [ $INSERT = true ]; then
				FILES+=" $GENERAL_FILE"
			fi
		done
	fi
	
	if [ -n "$FILES" ]; then
		local tmp_patch="/tmp/$PROJECT_NAME/patchs"
		local step
		 
		mkdir -p $tmp_patch
		cd $WORLD_PATH
		
		step="PATCH SRC"
		for PATCH in ${FILES[@]}; do
			cp $PATCH $tmp_patch
			sed -i '' "s/@@PROJECT_NAME/$PROJECT_NAME/g" $tmp_patch/${PATCH##*/}
			log_command "$current_domain" "$step" "patch -p1 < $tmp_patch/${PATCH##*/}" false || die
		done
		rm -rf $tmp_patch
	fi
}

world_make_chroot()
{
	CONF_FILES=
	if [ -e $WORLD_MAKE_CONF ] && [ ! -c $WORLD_MAKE_CONF ]; then
		CONF_FILES+=" __MAKE_CONF=$WORLD_MAKE_CONF"
	fi
	if [ -e $WORLD_SRC_CONF ] && [ ! -c $WORLD_SRC_CONF ]; then
		CONF_FILES+=" SRCCONF=$WORLD_SRC_CONF"
	fi
	
	CHROOT_WORLD_MAKE_FLAGS="$WORLD_MAKE_FLAG $WORLD_FLAGS $CONF_FILES"
	CHROOT_INSTALL_MAKE_FLAGS="$CONF_FILES"
	CHROOT_DISTRIBUTION_MAKE_FLAGS="$CONF_FILES"
	
	mkdir -p $WORLD_PATH/etc
	cp /etc/resolv.conf $WORLD_PATH/etc/resolv.conf
	# Necessary for poudriere
	echo 'WITH_PKGNG=yes' > $WORLD_PATH/etc/make.conf
	cd $WORLD_SRC_PATH
	
	local step run		

	step="PREPARE CHROOT"
	run="{
			make $CHROOT_WORLD_MAKE_FLAGS buildworld $WORLD_CLEAN || exit 1
			make $CHROOT_INSTALL_MAKE_FLAGS installworld DESTDIR=$WORLD_PATH || exit 1
			make $CHROOT_DISTRIBUTION_MAKE_FLAGS distribution $WORLD_CLEAN DESTDIR=$WORLD_PATH || exit 1
		}"
	
	log_command "$current_domain" "$step" "$run" || die
}

world_main()
{
	world_prepare
	world_custom_src
	world_set_clean
	world_make_chroot
}

############################################################ MAIN

world_main "$@"
