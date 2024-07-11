#!/bin/bash
set -ex

IFS='.' read -ra VER_ARR <<< "$PKG_VERSION"

# temporary prefix to be able to install files more granularly
mkdir temp_prefix

MAJOR_EXT="${VER_ARR[0]}"
# default SOVER for tagged releases is major.minor version
SOVER_EXT="${VER_ARR[0]}.${VER_ARR[1]}"
# for rc's, both MAJOR_EXT & SOVER_EXT get suffixes
if [[ "${PKG_VERSION}" == *rc* ]]; then
    # rc's get "rc" without the number
    MAJOR_EXT="${MAJOR_EXT}rc"
    SOVER_EXT="${SOVER_EXT}rc"
elif [[ "${PKG_VERSION}" == *dev0 ]]; then
    # otherwise with git suffix
    MAJOR_EXT="${MAJOR_EXT}git"
    SOVER_EXT="${SOVER_EXT}git"
fi

if [[ "${PKG_NAME}" == libllvm-c* ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # only libLLVM-C
    mv ./temp_prefix/lib/libLLVM-C${SOVER_EXT}${SHLIB_EXT} $PREFIX/lib
elif [[ "${PKG_NAME}" == libllvm* ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # all other libraries
    mv ./temp_prefix/lib/libLLVM-${MAJOR_EXT}${SHLIB_EXT} $PREFIX/lib
    mv ./temp_prefix/lib/lib*.so.${SOVER_EXT} $PREFIX/lib || true
    mv ./temp_prefix/lib/lib*.${SOVER_EXT}.dylib $PREFIX/lib || true
elif [[ "${PKG_NAME}" == "bolt" ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # only bolt binaries
    mkdir -p $PREFIX/bin
    mv ./temp_prefix/bin/llvm-bolt* $PREFIX/bin
    mv ./temp_prefix/bin/perf2bolt $PREFIX/bin
elif [[ "${PKG_NAME}" == "llvm-tools" ]]; then
    cmake --install ./build --prefix=./temp_prefix
    # everything in /bin & /share
    mv ./temp_prefix/bin/* $PREFIX/bin
    mv ./temp_prefix/share/* $PREFIX/share
    # except one binary that belongs to llvmdev
    rm $PREFIX/bin/llvm-config
else
    # llvmdev: install everything else
    cmake --install ./build --prefix=$PREFIX
fi

rm -rf temp_prefix
