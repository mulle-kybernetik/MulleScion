#! /bin/sh

set -e

TESTDIR="`pwd -P`"

mulle-bootstrap build -c Debug -k

cd ..


if [ -f .CC ]
then
   OPTIONS="-DCMAKE_C_COMPILER=`cat .CC` -DCMAKE_CXX_COMPILER=`cat .CXX`"
fi

if [ -d build ]
then
   rm -rf build
fi
mkdir build


cd build
   eval cmake -DCMAKE_OSX_SYSROOT=macosx \
              -DCMAKE_INSTALL_PREFIX="'${TESTDIR}'" \
              ${OPTIONS} \
              -DCMAKE_BUILD_TYPE=Debug ..
   make -j 4 "$@" install
