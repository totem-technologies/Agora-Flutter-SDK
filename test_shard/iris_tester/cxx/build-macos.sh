#!/usr/bin/env bash

set -e
set -x

MY_PATH=$(dirname "$0")

SRC_PATH=${MY_PATH}

# pushd ${MY_PATH}/../../../macos
#     flutter packages get
#     pod install
# popd

if [ ! -d "$SRC_PATH/build/mac" ]; then
    mkdir -p ${SRC_PATH}/build/mac
fi

pushd ${SRC_PATH}/build/mac

cmake \
    -G Xcode \
    -DPLATFORM="MAC" \
    -DCMAKE_OSX_ARCHITECTURES="x86_64" \
    -DCMAKE_BUILD_TYPE="Debug" \
    -DRUN_TEST=1 \
    "${SRC_PATH}"
cmake --build . --config "Debug"

popd

cp -RP "${SRC_PATH}/build/mac/Debug/libiris_tester.a" "${SRC_PATH}/../macos/libiris_tester.a"