#!/bin/sh

############################################################ CONFIGURATIONS

set -e

#
# Global exit status variables
#
SUCCESS=0
FAILURE=1

SCRIPT_DIR="$(dirname $0)"

MEDIAS=''
for VAR in $*; do
	if [ "x$VAR" = "x-m" ]; then
		shift
		MEDIAS="$MEDIAS $1"
		shift
	fi
done

if [ $# -lt 4 ]; then
	echo Usage: $0 '[-m] media(s) project_name pkg_repo_path output_dir RELEASE_MAKE_FLAGS'
	echo "MEDIAS can be iso img and multiple; eg: -m iso -m img"
	exit 1
fi

: ${TARGET_ARCH=$(uname -p)}

PROJECT_NAME=$1;shift
PORT_PKG_REPO_PATH_TEMP=$1;shift
OUT_DIR=$1;shift
RELEASE_MAKE_FLAGS=$@

TMP_DIR="/tmp/$PROJECT_NAME"
MEDIAS_DIR="$TMP_DIR/medias"
DIST_DIR="$TMP_DIR/dist"
WORLDDIR="/usr/src"

DEST_DIR="$MEDIAS_DIR/system"

MEDIA_NAME="${PROJECT_NAME}-${PROJECT_VERSION}_${PROJECT_REVISION}-${TARGET_ARCH}"

############################################################ FUNCTIONS

common()
{
	export ASSUME_ALWAYS_YES=1

	PKG_ABI=$(pkg -vv | grep ^ABI | awk '{print $3}' | cut -d'"' -f2)
	
	: ${PORT_PKG_NAME:=$PKG_ABI}
	
	echo "PACKAGE BASE AND KERNEL FOR $MEDIA"
	
	cd $WORLDDIR
	mkdir -p $DIST_DIR
	## base.txz:
	make $RELEASE_MAKE_FLAGS distributeworld DISTDIR=$DIST_DIR
	# Set up mergemaster root database
	sh $WORLDDIR/release/scripts/mm-mtree.sh -m $WORLDDIR -F \
		$ARCH_FLAGS -D "$DIST_DIR/base"
	# Package all components 
	make $RELEASE_MAKE_FLAGS packageworld DISTDIR=$DIST_DIR
	
	## kernel.txz:
	make $RELEASE_MAKE_FLAGS distributekernel packagekernel DISTDIR=$DIST_DIR
	
	sh $WORLDDIR/release/scripts/make-manifest.sh $DIST_DIR/*.txz > $DIST_DIR/MANIFEST
}

install_system()
{
	echo "INSTALL $MEDIA SYSTEM"
	
	mkdir -p $DEST_DIR
	
	cd $WORLDDIR
 	# Install system for all medias
	make $RELEASE_MAKE_FLAGS installkernel installworld distribution DESTDIR=$DEST_DIR \
		WITHOUT_RESCUE=1 WITHOUT_KERNEL_SYMBOLS=1 \
		WITHOUT_PROFILE=1 WITHOUT_SENDMAIL=1 WITHOUT_ATF=1 WITHOUT_LIB32=1
}

copy_files()
{
	echo "COPY $MEDIA FILES"
	
	# Copy distfiles
	mkdir -p $DEST_DIR/usr/freebsd-dist
	cp $DIST_DIR/*.txz $DIST_DIR/MANIFEST $DEST_DIR/usr/freebsd-dist
	
	# Set up installation environment
	ln -fs /tmp/bsdinstall_etc/resolv.conf $DEST_DIR/etc/resolv.conf
	echo sendmail_enable=\"NONE\" > $DEST_DIR/etc/rc.conf
	echo hostid_enable=\"NO\" >> $DEST_DIR/etc/rc.conf
	cp $SCRIPT_DIR/rc.local $DEST_DIR/etc
	sed -i '' "s/@@PROJECT_NAME/$PROJECT_NAME/g" $DEST_DIR/etc/rc.local
	cp $SCRIPT_DIR/installerconfig $DEST_DIR/etc
	# Copy bsdinstall script
	cp $SCRIPT_DIR/script $DEST_DIR/usr/libexec/bsdinstall
	chmod 555 $DEST_DIR/usr/libexec/bsdinstall/script
	
	# Copy Repo
	mkdir -p $DEST_DIR/packages/$PORT_PKG_NAME
	cp -R $PORT_PKG_REPO_PATH_TEMP/ $DEST_DIR/packages/$PORT_PKG_NAME
	
	# Copy rc.conf
	mkdir -p $DEST_DIR/usr/local/$PROJECT_NAME
	cp $SCRIPT_DIR/rc.conf $DEST_DIR/usr/local/$PROJECT_NAME
	
	# Create repo conf for installation
	cat << EOF > $DEST_DIR/etc/pkg/install.conf
install: {
	url: "file:///packages/$PORT_PKG_NAME",
	mirror_type: "none",
	enabled: yes
}
EOF
}

create_image()
{
	echo "CREATE $MEDIA IMAGE"
	
	mkdir -p $OUT_DIR
	
	case $MEDIA in
		iso)
			mkdir -p $OUT_DIR/iso
			
			bootable="-o bootimage=i386;$DEST_DIR/boot/cdboot -o no-emul-boot"
			LABEL="$(echo ${PROJECT_NAME}_Install | tr '[:lower:]' '[:upper:]')"
			
			publisher="The ${PROJECT_NAME} Project."
			echo "/dev/iso9660/$LABEL / cd9660 ro 0 0" > $DEST_DIR/etc/fstab
			makefs -t cd9660 $bootable -o rockridge -o label=$LABEL -o publisher="$publisher" $OUT_DIR/iso/${MEDIA_NAME}.iso $DEST_DIR
			rm ${DEST_DIR}/etc/fstab
			;;
		img)
			mkdir -p $OUT_DIR/img
		
			# Make memstick
			echo "/dev/ufs/${PROJECT_NAME}_Install / ufs ro,noatime 1 1" > $DEST_DIR/etc/fstab
			makefs -B little -o label=${PROJECT_NAME}_Install $OUT_DIR/img/${MEDIA_NAME}.img $DEST_DIR
			if [ $? -ne 0 ]; then
			  echo "makefs failed"
			  exit 1
			fi
			rm $DEST_DIR/etc/fstab
			
			unit=`mdconfig -a -t vnode -f $OUT_DIR/img/${MEDIA_NAME}.img`
			if [ $? -ne 0 ]; then
			  echo "mdconfig failed"
			  exit 1
			fi
			gpart create -s BSD $unit
			gpart bootcode -b $DEST_DIR/boot/boot $unit
			gpart add -t freebsd-ufs $unit
			mdconfig -d -u $unit
			;;
		ftp)
			mkdir -p $OUT_DIR/ftp
			cp $DIST_DIR/*.txz $DIST_DIR/MANIFEST $OUT_DIR/ftp
			;;
		*)
			exit 1
			;;
	esac
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

cleanup_dir()
{
	[ "$#" -lt 1 ] && die;
	
	local DIRS="$@"
	
	for DIR in $DIRS; do
		if [ -d "$DIR" ]; then
			chflags -R 0 $DIR
			rm -rf $DIR
		fi
	done
}

main()
{
	local CLEAN_COMMAND="cleanup_dir $OUT_DIR $TMP_DIR"
	
	trap "$($CLEAN_COMMAND)" EXIT

	common
	install_system
	copy_files
	
	for MEDIA in $MEDIAS; do
		create_image
	done
}

############################################################ MAIN

#
# Trap signals so we can recover gracefully
#
trap 'die'	SIGINT SIGTERM SIGPIPE SIGXCPU SIGXFSZ \
			SIGFPE SIGTRAP SIGABRT SIGSEGV
trap '' 	SIGALRM SIGPROF SIGUSR1 SIGUSR2 SIGHUP SIGVTALRM

main "$@"
