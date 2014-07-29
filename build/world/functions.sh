#!/usr/bin/env bash

############################################################ GLOBALS

WORLD_PATH="$WORK_PATH/world"
WORLD_SRC_PATH="$WORLD_PATH/usr/src"

WORLD_SVN_URL="svn://svn.freebsd.org/base/$BRANCH/$RELEASE_VERSION"

NCPU=$(sysctl -n hw.ncpu)
if [ $NCPU -gt 1 ]; then
	WORLD_FLAGS="-j$NCPU"
	WORLD_KERNEL_FLAGS="-j$(expr $NCPU / 2)"
fi

WORLD_MAKE_FLAG="-s"

: ${WORLD_CLEAN:=NO_CLEAN=yes}
: ${WORLD_KERNELCLEAN:=NO_KERNELCLEAN=yes}

WORLD_MAKE_CONF="$ROOT_DIR/build/world/conf/make.conf"
WORLD_SRC_CONF="$ROOT_DIR/build/world/conf/src.conf"
WORLD_KERNEL_CONF="$ROOT_DIR/build/world/conf/kernel_conf.$TARGET_ARCH"

WORLD_CONF_PATH="$PROJECT_PATH/conf"

WORLD_CUSTOM_SRC_DIR="$ROOT_DIR/build/world/custom_src"
WORLD_GENERAL_CUSTOM_DIR="All"

WORLD_KERNEL_CONF_PATH="$WORLD_PATH/usr/src/sys/$TARGET_ARCH/conf"

WORLD_PORTS_PATH="$WORLD_PATH/usr/ports"

############################################################ FUNCTIONS

world_init()
{
	local CONF_FILES _MAKE_CONF _SRC_CONF
	
	CONF_FILES=
	if [ -e $WORLD_MAKE_CONF ] && [ ! -c $WORLD_MAKE_CONF ]; then
		_MAKE_CONF="$WORLD_CONF_PATH/${WORLD_MAKE_CONF##*/}"
		mkdir -p $WORLD_PATH$WORLD_CONF_PATH
		cp $WORLD_MAKE_CONF $WORLD_PATH/${_MAKE_CONF}
		CONF_FILES+=" __MAKE_CONF=${_MAKE_CONF}"
	fi
	if [ -e $WORLD_SRC_CONF ] && [ ! -c $WORLD_SRC_CONF ]; then
		_SRC_CONF="$WORLD_CONF_PATH/${WORLD_SRC_CONF##*/}"
		mkdir -p $WORLD_PATH$WORLD_CONF_PATH
		cp $WORLD_SRC_CONF $WORLD_PATH/${_SRC_CONF}
		CONF_FILES+=" SRCCONF=${_SRC_CONF}"
	fi
	
	KERNEL_MAKE_FLAGS=
	if [ -e $WORLD_KERNEL_CONF ] && [ ! -c $WORLD_KERNEL_CONF ]; then
		if [ -d $WORLD_KERNEL_CONF_PATH ]; then
			cp $WORLD_KERNEL_CONF $WORLD_KERNEL_CONF_PATH/$PROJECT_NAME
			KERNEL_MAKE_FLAGS="KERNCONF=\"$PROJECT_NAME\""
			RELEASE_MAKE_FLAGS="KERNCONF=\"$PROJECT_NAME\""
		else
			die
		fi
	fi
	
	WORLD_MAKE_FLAGS="$WORLD_MAKE_FLAG $WORLD_FLAGS $ARCH_FLAGS $CONF_FILES"
	KERNEL_MAKE_FLAGS+=" $WORLD_MAKE_FLAG $WORLD_KERNEL_FLAGS $ARCH_FLAGS $CONF_FILES"
	RELEASE_MAKE_FLAGS+=" $WORLD_MAKE_FLAG $CONF_FILES"
	
	# Add make cleandepend && make depend for make kernel if no clean is set
	WORLD_KERNEL_DEPEND=
	if [ "$WORLD_KERNELCLEAN" = "NO_KERNELCLEAN=yes" ]; then
		WORLD_KERNEL_DEPEND+="cleandepend depend"
	fi
	
	world_mount_dev
}

world_svn_cleanup()
{
	# Parameter must be provided
	[ "$#" -ne 1 ] && die;

	local DIR="$1"
	local step run

	# Replace all modified files by current revision
	step="Clean SOURCE WORLD"
	run="svnlite revert -R $DIR"
	log_command "$current_domain" "$step" "$run" && return $SUCCESS || return $FAILURE
	
	# Remove all added files
	rm -rf $(svnlite status $DIR | awk 'FS="?" {print $2}')
}

world_svn_update()
{
	# Parameter must be provided
	[ "$#" -ne 1 ] && die;

	local DIR="$1"
	local step run
	
	step="Update SOURCE WORLD"
	run="svnlite up $DIR"
	log_command "$current_domain" "$step" "$run" && return $SUCCESS || return $FAILURE
}

world_svn_create()
{
	# Parameter must be provided
	[ "$#" -ne 2 ] && die;

	local DIR="$1"
	local URL="$2"
	local step run

	if [ -d "$DIR" ]; then
		$ROOT_DIR/build/main/clean.sh "$DIR"
	fi

	step="Create SOURCE WORLD"
	run="svnlite co $URL $DIR 2>&1"
	log_command "$current_domain" "$step" "$run"
	
	create_clean_flag "world"
}

world_svn_ok()
{
	## Parameter must be provided
	[ "$#" -ne 1 ] && die;

	local SVN_CHECK
	local DIR="$1"

	SVN_CHECK=$(svnlite info $DIR 2>&1| grep "^URL:" | awk 'FS=" " {print $2}')

	if [ -d "$DIR" ] && [ "$SVN_CHECK" = "$WORLD_SVN_URL" ]; then
		return $SUCCESS
	else
		return $FAILURE
	fi
}

world_mount_dev()
{
	mount -t devfs devfs $WORLD_PATH/dev
	trap "umount $WORLD_PATH/dev" EXIT
}

world_set_clean()
{
	if check_clean_flag "world"; then
		WORLD_CLEAN=
		WORLD_KERNELCLEAN=
	fi
}
world_cleanup()
{
	if [ -d "$WORLD_PATH$PROJECT_PATH" ]; then
		rm -rf $WORLD_PATH$PROJECT_PATH
	fi
	if [ -f "$WORLD_KERNEL_CONF_PATH/$PROJECT_NAME" ]; then
		rm $WORLD_KERNEL_CONF_PATH/$PROJECT_NAME
	fi	
	if [ -d "$WORLD_PATH/tmp" ]; then
		# Cleanup tmp directory in chroot
		chflags -R 0 $WORLD_PATH/tmp/
		rm -rf $WORLD_PATH/tmp/*
	fi
}

############################################################ MAIN

trap "world_cleanup" 	EXIT

