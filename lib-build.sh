#!/bin/bash

set -ex
if [ "$(uname)" != "Darwin" ]; then
    echo "Only MacOS is supported"
    exit 1
fi

ED25519_PATH="ed25519"
BLAKE2_PATH="blake2_mjosref"
IROHA_ED25519_PATH="iroha-ed25519"
SR25519_PATH="sr25519-crust"

SR25519_BINARY="libsr25519crust.a"

SR25519_BINARY_PATH="$SR25519_PATH/build/release/$SR25519_BINARY"

SRC_PATHS=(
    $ED25519_PATH
    $BLAKE2_PATH
    $IROHA_ED25519_PATH
    $SR25519_PATH
)
INCLUDE_PATHS=(
    "include/include"
    "include/blake2"
    "include/ed25519/ed25519"
    "include/sr25519"
)
STATIC_LIB_PATHS=(
    "libed25519_sha2.a"
    "libblake2.a"
    "libed25519.a"
    "libsr25519crust.a"
)
FINAL_PATHS=(
    "ed25519Imp"
    "blake2Imp"
    "IrohaCryptoImp"
    "sr25519Imp"
)

CMAKE_PATH="ios-cmake"
LIB_PATH="lib"


command -v xcodebuild > /dev/null 2>&1 || { echo >&2 "xcodebuild is required but it's not installed.  Aborting.";
    exit 1; }

CORES=$(getconf _NPROCESSORS_ONLN)
if [ "$CORES" -gt 1 ]; then
    CORES=$((CORES - 1))
fi

for SRC_PATH in ${SRC_PATHS[*]}; do
   [ -d $SRC_PATH ] && rm -rf $SRC_PATH
done

for FINAL_PATH in ${FINAL_PATHS[*]}; do
   [ -d $FINAL_PATH ] && rm -rf $FINAL_PATH
   mkdir $FINAL_PATH
done

[ -d $CMAKE_PATH ] && rm -rf $CMAKE_PATH

# ios toolchain file for cmake
git clone https://github.com/leetal/ios-cmake
(cd "./$CMAKE_PATH"; git checkout ad96a372b168930c2a1ff9455e1a9ccb13021617)

git clone https://github.com/ERussel/ed25519.git
(cd "./$ED25519_PATH"; git checkout master)

git clone https://github.com/ERussel/blake2_mjosref.git
(cd "./$BLAKE2_PATH"; git checkout master)

git clone https://github.com/hyperledger/iroha-ed25519.git
(cd "./$IROHA_ED25519_PATH"; git checkout tags/1.3.1)

git clone https://github.com/svojsu/sr25519-crust.git
(cd "./$SR25519_PATH"; git checkout dde124ed66345938f22569bda3274f331fcb0533)

[ -d $LIB_PATH ] && rm -rf $LIB_PATH
mkdir $LIB_PATH

PLATFORM="OS64COMBINED"

BUILDS=()

IOS_TOOLCHAIN_ARGS=( -DCMAKE_TOOLCHAIN_FILE="$PWD"/ios-cmake/ios.toolchain.cmake -DPLATFORM=$PLATFORM )

[ -d "$SR25519_PATH/build" ] && rm -rf $"$SR25519_PATH/build"
(cd "./$SR25519_PATH"; mkdir build; cd "./build"; mkdir release)

(cd "./$SR25519_PATH"; cargo lipo --release)
cp -R "$SR25519_PATH/target/universal/release/$SR25519_BINARY" "$SR25519_BINARY_PATH"
    
for key in "${!SRC_PATHS[@]}"; do
    SRC_PATH=${SRC_PATHS[$key]}
    PLATFORM_PATH="$LIB_PATH/$SRC_PATH/$PLATFORM"
    INSTALL_ARGS=( -DCMAKE_INSTALL_PREFIX=$PLATFORM_PATH )
    BUILDS+=("$PLATFORM_PATH/${STATIC_LIB_PATHS[$key]}")
    
    [ -d $PLATFORM_PATH ] && rm -rf $PLATFORM_PATH

    cmake -DCMAKE_BUILD_TYPE="Release" "${IOS_TOOLCHAIN_ARGS[@]}" "${INSTALL_ARGS[@]}" -G Xcode -DTESTING=OFF -DBUILD=STATIC -H./$SRC_PATH -B./$SRC_PATH/build
    
    VERBOSE=1 cmake --build ./$SRC_PATH/build --config Release
    VERBOSE=1 cmake --install ./$SRC_PATH/build --config Release
    
    lipo -create "$PLATFORM_PATH/lib/${STATIC_LIB_PATHS[$key]}" -output "${FINAL_PATHS[$key]}/${STATIC_LIB_PATHS[$key]}"
    cp -R "$PLATFORM_PATH/${INCLUDE_PATHS[$key]}" "${FINAL_PATHS[$key]}/include"
    
    [ -d $SRC_PATH ] && rm -rf $SRC_PATH
done

[ -d $CMAKE_PATH ] && rm -rf $CMAKE_PATH
[ -d $LIB_PATH ] && rm -rf $LIB_PATH
