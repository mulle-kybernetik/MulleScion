#! /bin/sh

set -e

TESTDIR="`pwd -P`"

mulle-bootstrap build -c Debug -k "$@"

if [ -d ../build ]
then
   rm -rf ../build
fi

mkdir ../build
cd ../build
   cmake -DCMAKE_OSX_SYSROOT=macosx \
         -DCMAKE_INSTALL_PREFIX="${TESTDIR}" \
         -DCMAKE_BUILD_TYPE=Debug ..
   make -j 4 install
