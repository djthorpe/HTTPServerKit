#!/bin/bash
# Build Mac OS X apps in Release configuration
#
# Syntax:
#   build-release.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../HTTPServerKit.xcodeproj

# build mac targets
xcodebuild -project ${PROJECT} -target "HTTPServerKit" -configuration ${CONFIGURATION} || exit -1


