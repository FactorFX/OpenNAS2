#!/usr/bin/env bash

############################################################ INCLUDES

. $ROOT_DIR/build/main/common.sh || exit 1

############################################################ FUNCTIONS

git_checkout_build()
{
	local git_last_tag current_tag current_tag
	
	cd $ROOT_DIR

	current_tag=$(git describe --abbrev=0 --tags)
	
	git fetch origin
	git fetch origin --tags
	git_last_tag=$(git describe $(git rev-list --tags --max-count=1))
	current_tag=$(git rev-parse --short)
	
	if [ "x$git_last_tag" != "x$current_tag" ]; then
		git pull --rebase
		git stash
		git checkout $git_last_tag
		git pull --rebase
		git stash pop
	fi
}

############################################################ MAIN

git_checkout_build
