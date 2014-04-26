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
REVISION="${DATE_REVISION}-${GIT_REVISION_HEAD}"
echo "REVISION=${REVISION}"

# perform the tagging
git tag -a -m "Tagging version ${REVISION}" "${REVISION}"
git push origin --tags
exit 1

# build mac targets
xcodebuild -project ${PROJECT} -target "HTTPServerKit" -configuration ${CONFIGURATION} || exit -1


