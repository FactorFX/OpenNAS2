#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/ports/functions.sh
include $ROOT_DIR/build/world/functions.sh

############################################################ FUNCTIONS

port_init()
{
	mkdir -p $PORT_JAIL $PORT_DISTFILES_CACHE
}

port_create_conf()
{
	cp $PORT_CONF_ORIG $PORT_CONF_DEST
	echo "BASEFS="$PORT_BASEFS"" >> $PORT_CONF_DEST
	echo "DISTFILES_CACHE="$PORT_DISTFILES_CACHE"" >> $PORT_CONF_DEST
	echo "PARALLEL_JOBS="$PORT_NCPU""  >> $PORT_CONF_DEST
}

port_check_tree()
{	
	if port_check_exist; then	
		port_poudriere_command update
	else
		port_poudriere_command create
	fi
}

port_umount_port_chroot()
{	
	if [ "x$(mount | grep $WORLD_PORTS_PATH)" != "x" ]; then
		umount $WORLD_PORTS_PATH
	fi
}

port_pkg_update()
{
	local NEW_PKG_VERSION OLD_PKG_VERSION

	mkdir -p $WORLD_PORTS_PATH
	mount -t nullfs $PORT_PORTS_DIR $WORLD_PORTS_PATH
	
	NEW_PKG_VERSION=$(chroot $WORLD_PATH make -f /usr/ports/ports-mgmt/pkg/Makefile -V DISTVERSION)
	OLD_PKG_VERSION=$(chroot $WORLD_PATH env ASSUME_ALWAYS_YES=yes pkg -v)
	
	if [[ "$OLD_PKG_VERSION" < "$NEW_PKG_VERSION" ]]; then
		world_mount_dev
		
		step="UPDATE PKG"
		run="chroot $WORLD_PATH make -C /usr/ports/ports-mgmt/pkg distclean reinstall distclean"
		log_command "$current_domain" "$step" "$run" false || die
	fi
	port_umount_port_chroot
}

port_pkg_clean()
{
	local retval
	
	
	# Clean package repo
	if [ -d "$PORT_PKG_REPO" ] && dirempty "$PORT_PKG_REPO"; then
		step="CLEAN PORTS, it takes a while..."
		run="$ENV_SETUP poudriere $PORT_EXTRA_PARAM pkgclean -y -f $PORT_LIST -j $PROJECT_NAME -p $PROJECT_NAME"
		log_command "$current_domain" "$step" "$run"
		retval=$?

		# If poudriere pkgclean is nok delete $PORT_PKG_REPO and restart
		[ $retval -eq $FAILURE ] && rm -rf $PORT_PKG_REPO
	fi
	
	exit $SUCCESS
}

port_prepare_jail()
{
	echo "$TARGET_ARCH" > $PORT_JAIL/arch
	echo "$WORLD_PATH" > $PORT_JAIL/mnt
	echo '' > $PORT_JAIL/method
	echo "$PORT_FREEBSD_VERSION" > $PORT_JAIL/version

	chroot -u root $WORLD_PATH /sbin/ldconfig -m /lib /usr/lib /usr/lib/compat
}

ports_options()
{
	. $PORT_OPTIONS_TABLE || exit $FAILURE

	local DIR

	for DIR in ${!PKG_OPTIONS[@]}; do
		mkdir -p $PORT_OPTIONS_DIR/$DIR
		echo "${PKG_OPTIONS[$DIR]}"  | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*\$//g' > $PORT_OPTIONS_DIR/$DIR/options
	done
}

port_adds()
{	
	for DIR in $(cd $PORT_EXTRA_DIR;find ./ -mindepth 2 -maxdepth 2 -type d); do
		# Cleanup extra ports
		if [ -d "$PORT_PORTS_DIR/$DIR" ]; then
			rm -rf $PORT_PORTS_DIR/$DIR
		fi	

		echo "${DIR#./}" > $PORT_LIST
	done
	
	# Copy extra ports
	cp -R $PORT_EXTRA_DIR/ $PORT_PORTS_DIR
	
	for PORT in $(cat $PORT_LIST); do
		cd $PORT_PORTS_DIR/$PORT
		for FILE in $(find ./ -type f); do
			sed -i '' "s/@@PROJECT_VERSION/$PROJECT_VERSION/g;s/@@PROJECT_REVISION/$PROJECT_REVISION/g" $FILE
		done
	done
}

port_main()
{
	port_init
	port_create_conf
	port_umount_port_chroot
	port_check_tree
	port_prepare_jail
	port_pkg_update
	port_adds
	ports_options
	port_pkg_clean
}

############################################################ MAIN
trap "port_umount_port_chroot"	EXIT

port_main "$@"
