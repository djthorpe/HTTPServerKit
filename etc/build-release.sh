#!/bin/bash
# Build Mac OS X apps in Release configuration
#
# Syntax:
#   build-release.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../HTTPServerKit.xcodeproj

# determine tag name
GIT_REVISION_HEAD=`git rev-parse HEAD`
DATE_REVISION=`date +"%Y%m%d"`
REVISION="${DATE_REVISION}-${GIT_REVISION_HEAD:0:7}"
UNPUSHED=`git log --branches --not --remotes --simplify-by-decoration --decorate --oneline`

# see what hasn't been pushed to origin
if [ "${UNPUSHED}" != "" ] ; then
	echo "Error: unpushed commits, use 'git push origin' first"
	echo "  ${UNPUSHED}"
fi

# perform the tagging
git tag -a -m "Tagging version ${REVISION}" "${REVISION}"
git push origin --tags

# build mac targets
xcodebuild -project ${PROJECT} -target "HTTPServerKit" -configuration ${CONFIGURATION} || exit -1

# report
echo "Tagged release: ${REVISION}"


