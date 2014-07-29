PROJECT_NAME?=OpenNAS
PROJECT_VERSION=2.0
PROJECT_REVISION=ALPHA
BUILD_DATE!=date '+%Y%m%d'
BUILD_TIME!=date '+%H%M%S'

ENV_SETUP=env PROJECT_NAME=${PROJECT_NAME} PROJECT_VERSION=${PROJECT_VERSION} PROJECT_REVISION=${PROJECT_REVISION} BUILD_DATE=${BUILD_DATE} BUILD_TIME=${BUILD_TIME}

RUN_COMMAND=$(ENV_SETUP) $(.CURDIR)/build
RUN_TARGET_COMMAND=$(RUN_COMMAND)/$@

export ROOT_DIR=$(.CURDIR)

all: world ports medias

.BEGIN: main

.PHONY : clean

checkout:
	@$(RUN_COMMAND)/main/git_checkout.sh

main: checkout
	@[ `id -u` -eq 0 ] || (echo "Needs to be run as root."; exit 1;)
	@$(RUN_TARGET_COMMAND)/check_bash.sh
	@$(RUN_TARGET_COMMAND)/check_requirement.sh

world:
	@$(RUN_TARGET_COMMAND)/prepare.sh
	@$(RUN_TARGET_COMMAND)/release.sh

medias:
	@$(RUN_TARGET_COMMAND)/create.sh

ports:
	@$(RUN_TARGET_COMMAND)/prepare.sh
	@$(RUN_TARGET_COMMAND)/release.sh
	
cleanlogs:
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/logs

ports_options:
	@$(RUN_COMMAND)/ports/ports_options.sh

clean:
	@$(RUN_COMMAND)/world/clean.sh

distclean:
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/work
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/logs
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/out

cleanworld:
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/work/world

cleanports:
	@$(RUN_COMMAND)/main/clean.sh $(.CURDIR)/work/poudriere
