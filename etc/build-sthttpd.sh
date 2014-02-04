#!/bin/sh

# Make sthttpd from source, and create a symbolic link
# to the compiled package.
#
# Syntax:
#   make-sthttpd.sh (input_tar) (output_directory) (flags)
#
# Flags:
#   --clean will always rebuild from clean sources

##############################################################
# Process command line arguments

SCRIPT_NAME=`basename ${0}`
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UNARCHIVE="${DERIVED_SOURCES_DIR}"
TARZ="${1}"
BUILD="${2}"
CLEAN=0
PLATFORM=mac_x86_64

for ARG in "$@"
do
  case ${ARG} in
    --clean )
      CLEAN=1
      ;;
  esac
done

##############################################################
# Sanity checks

# Check for the TAR file to make sure it exists
if [ "${#}" == "0" ] || [ "${TARZ}" == "" ] || [ ! -e "${TARZ}" ]
then
  echo "Syntax error: ${SCRIPT_NAME} {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean)"
  exit 1
fi

# Check for the BUILD directory
if [ "${BUILD}XX" == "XX" ] || [ ! -d ${BUILD} ]
then
  echo "Syntax error: ${SCRIPT_NAME} {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean)"
  exit 1
fi

##############################################################
# Set version number

VERSION=`basename ${TARZ} | sed 's/\.tar\.gz//'`
if [ "${UNARCHIVE}XX" == "XX" ]
then
  UNARCHIVE=${TMPDIR}
fi
if [ "${UNARCHIVE}XX" == "XX" ]
then
  echo "Syntax error: ${SCRIPT_NAME} {INPUT_TAR_GZ} {OUTPUT_FOLDER} (--clean)"
  exit 1
fi

if [ ! -d "${UNARCHIVE}" ]
then
  echo "mkdir ${UNARCHIVE}"
  mkdir -pv "${UNARCHIVE}"
fi

##############################################################
# Architectures

DEVELOPER_PATH=`xcode-select --print-path`
if [ ! -d "$DEVELOPER_PATH" ]; then
  echo "XCode not installed"
  exit -1
fi

MACOSX_DEPLOYMENT_TARGET=10.8

case ${PLATFORM} in
  mac_x86_64 )
    ARCH="x86_64"
    DEVROOT="${DEVELOPER_PATH}/Platforms/MacOSX.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk"
    ;;
  * )
    echo "Unknown build platform: ${PLATFORM}"
    exit 1
esac

CC="/usr/bin/gcc -arch ${ARCH}"
CPPFLAGS=""
CFLAGS="-isysroot ${SDKROOT} ${CPPFLAGS}"
LDFLAGS="-Wl,-syslibroot,${SDKROOT} -lz"
CONFIGURE_FLAGS=""

##############################################################
# Check to see if already built, ignore if so

PREFIX="${BUILD}/${VERSION}/${PLATFORM}"

if [ -e "${PREFIX}" ] && [ ${CLEAN} == 0 ]
then
  echo "Assuming already exists: ${PREFIX}"
  exit 0
fi

##############################################################
# remove existing build directory, unarchive

# Check for the UNARCHIVE  directories, use TMP if necessary
if [ "${UNARCHIVE}" == "" ]
then
UNARCHIVE="${TMPDIR}/${VERSION}/src"
fi

rm -fr "${UNARCHIVE}"
mkdir "${UNARCHIVE}"
tar -C "${UNARCHIVE}" -zxf "${TARZ}"

##############################################################
# Building

pushd "${UNARCHIVE}/${VERSION}"

echo "Derived data: ${UNARCHIVE}"
echo "    Build to: ${PREFIX}"
echo "Architecture: ${ARCH}"
echo "       Flags: ${CONFIGURE_FLAGS}"

./configure CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CPPFLAGS="${CPPFLAGS}" --prefix="${PREFIX}" ${CONFIGURE_FLAGS}
make && make install-exec

if [ $? != 0 ]; then
  echo "Error building sthttpd"
  exit -1
fi

popd

##############################################################
# Make symbolic links

rm -f "${BUILD}/sthttpd-current-${PLATFORM}"
ln -s "${PREFIX}" "${BUILD}/sthttpd-current-${PLATFORM}"
echo "${BUILD}/sthttpd-current-${PLATFORM}"

