#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1
include $ROOT_DIR/build/ports/functions.sh

############################################################ FUNCTIONS

poudriere ${PORT_EXTRA_PARAM} options -f ${PORT_LIST} -j ${PROJECT_NAME} -p ${PROJECT_NAME}
