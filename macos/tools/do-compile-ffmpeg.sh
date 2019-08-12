#! /usr/bin/env bash

RED='\033[0;31m'
Green='\033[0;33m'
NC='\033[0m' # No Color

echo "--------------------"
echo "${RED}[*] check input params [检查输入参数] $1 ${NC}"
echo "--------------------"

ARCH=$1
BUILD_OPT=$2

echo "ARCH[架构] = $ARCH"
echo "BUILD_OPT[构建参数] = $BUILD_OPT"

if [ -z "$ARCH" ]; then
    echo "You must specific an architecture 'x86_64, ...'."
    exit 1
fi


BUILD_ROOT=`pwd`/tools

BUILD_NAME=

FFMPEG_SOURCE_PATH=

# compiler options
CFG_FLAGS=

# --extra-cflags would provide extra command-line switches for the C compiler,
DEP_INCLUDES=
CFLAGS=

# --extra-ldflags would provide extra flags for the linker. 
DEP_LIBS=
LDFLAGS=

PRODUCT=product

TOOLCHAIN_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk"

TOOLCHAIN_AS="/Applications/Xcode.app/Contents/Developer/usr/bin/gcc"
TOOLCHAIN_LD="/Applications/Xcode.app/Contents/Developer/usr/bin/ld"

echo ""
echo "--------------------"
echo "${RED}[*] make pre params [确定预参数] ${NC}"
echo "--------------------"

if [ "$ARCH" = "x86_64" ]; then
    
    BUILD_NAME=ffmpeg-x86_64

    FFMPEG_SOURCE_PATH=${BUILD_ROOT}/${BUILD_NAME}

    CFG_FLAGS="$CFG_FLAGS --arch=x86_64 --cpu=x86_64"

    DEP_INCLUDES="$DEP_INCLUDES -I/usr/local/include"
    CFLAGS="$CFLAGS"

    DEP_LIBS="$DEP_LIBS -L/usr/local/lib"
    LDFLAGS="$LDFLAGS -Wl,-no_compact_unwind"

else
    echo "unknown architecture $ARCH";
    exit 1
fi

if [ ! -d ${FFMPEG_SOURCE_PATH} ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $BUILD_NAME"
    echo ""
    exit 1
fi

FFMPEG_OUTPUT_PATH=${BUILD_ROOT}/build/${BUILD_NAME}/output
SHARED_OUTPUT_PATH=${BUILD_ROOT}/../${PRODUCT}/${BUILD_NAME}

mkdir -p ${FFMPEG_OUTPUT_PATH}
mkdir -p ${SHARED_OUTPUT_PATH}

echo "BUILD_NAME[构建名称] = $BUILD_NAME"
echo ""
echo "CFG_FLAGS[编译参数] = $CFG_FLAGS"
echo ""
echo "DEP_INCLUDES[编译器依赖头文件] = $DEP_INCLUDES"
echo ""
echo "CFLAGS[编译器参数] = $CFLAGS"
echo ""
echo "DEP_LIBS[链接器依赖库] = $DEP_LIBS"
echo ""
echo "LDFLAGS[链接器参数] = $LDFLAGS"
echo ""
echo "TOOLCHAIN_SYSROOT[编译链Root] = $TOOLCHAIN_SYSROOT"
echo ""
echo "TOOLCHAIN_AS[] = $TOOLCHAIN_AS"
echo ""
echo "FFMPEG_SOURCE_PATH[源码目录] = $FFMPEG_SOURCE_PATH"
echo ""
echo "FFMPEG_OUTPUT_PATH[编译输出目录] = $FFMPEG_OUTPUT_PATH"

echo ""
echo "--------------------"
echo "${RED}[*] make ffmpeg params [确定FFmpeg编译参数]  ${NC}"
echo "--------------------"

CFG_FLAGS="$CFG_FLAGS --prefix=$FFMPEG_OUTPUT_PATH"
CFG_FLAGS="$CFG_FLAGS --sysroot=$TOOLCHAIN_SYSROOT"
CFG_FLAGS="$CFG_FLAGS --cc=clang"
CFG_FLAGS="$CFG_FLAGS --as=${TOOLCHAIN_AS}"
CFG_FLAGS="$CFG_FLAGS --strip="
CFG_FLAGS="$CFG_FLAGS --host-cflags= --host-ldflags="
CFG_FLAGS="$CFG_FLAGS --enable-cross-compile"
CFG_FLAGS="$CFG_FLAGS --target-os=darwin"
CFG_FLAGS="$CFG_FLAGS --disable-stripping"

case "$BUILD_OPT" in
    debug)
        CFG_FLAGS="$CFG_FLAGS --disable-optimizations"
        CFG_FLAGS="$CFG_FLAGS --enable-debug"
        CFG_FLAGS="$CFG_FLAGS --disable-small"
    ;;
    *)
        CFG_FLAGS="$CFG_FLAGS --enable-optimizations"
        CFG_FLAGS="$CFG_FLAGS --disable-debug"
        CFG_FLAGS="$CFG_FLAGS --enable-small"
    ;;
esac

export COMMON_CFG_FLAGS=
. ${BUILD_ROOT}/../config/module.sh

CFG_FLAGS="$CFG_FLAGS $COMMON_CFG_FLAGS"

echo "PATH[环境变量] = $PATH"
echo ""
echo "CFG_FLAGS[编译参数] = $CFG_FLAGS"
echo ""
echo "DEP_INCLUDES[编译器依赖头文件] = $DEP_INCLUDES"
echo ""
echo "DEP_LIBS[链接器依赖库] = $DEP_LIBS"
echo ""
echo "CFLAGS[编译器参数] = $CFLAGS"
echo ""
echo "LDFLAGS[链接器参数] = $LDFLAGS"

echo "--------------------"
echo "${RED}[*] configurate ffmpeg [配置FFmpeg] ${NC}"
echo "--------------------"

cd ${FFMPEG_SOURCE_PATH}

./configure ${CFG_FLAGS} \
    --extra-cflags="$CFLAGS" \
    --extra-ldflags="$DEP_LIBS $LDFLAGS" 

make clean

echo ""
echo "--------------------"
echo "${RED}[*] compile ffmpeg [编译FFmpeg] ${NC}"
echo "--------------------"
echo "FFMPEG_OUTPUT_PATH = $FFMPEG_OUTPUT_PATH"

make install -j8  > /dev/null

cp -r ${FFMPEG_OUTPUT_PATH}/include ${SHARED_OUTPUT_PATH}/include
cp -r ${FFMPEG_OUTPUT_PATH}/lib ${SHARED_OUTPUT_PATH}/lib


# LINK_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
# ASSEMBLER_SUB_DIRS="x86"

# LINK_C_OBJ_FILES=
# LINK_ASM_OBJ_FILES=
# for MODULE_DIR in ${LINK_MODULE_DIRS}
# do
#     C_OBJ_FILES="`pwd`/$MODULE_DIR/*.o"
#     if ls ${C_OBJ_FILES} 1> /dev/null 2>&1; then
#         echo "link $MODULE_DIR/*.o"
#         LINK_C_OBJ_FILES="$LINK_C_OBJ_FILES $C_OBJ_FILES"
#     fi

#     for ASM_SUB_DIR in ${ASSEMBLER_SUB_DIRS}
#     do
#         ASM_OBJ_FILES="`pwd`/$MODULE_DIR/$ASM_SUB_DIR/*.o"
#         if ls ${ASM_OBJ_FILES} 1> /dev/null 2>&1; then
#             echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
#             LINK_ASM_OBJ_FILES="$LINK_ASM_OBJ_FILES $ASM_OBJ_FILES"
#         fi
#     done
# done

# echo "LINK_C_OBJ_FILES = $LINK_C_OBJ_FILES"
# echo ""
# echo "LINK_ASM_OBJ_FILES = $LINK_ASM_OBJ_FILES"
# echo ""
# echo "LDFLAGS = $LDFLAGS"
# echo ""
# echo "DEP_LIBS = $DEP_LIBS"

# CLANG="/Library/Developer/CommandLineTools/usr/bin/clang"
# ${CLANG} -v -lm -lz -shared ${LDFLAGS} \
#     ${LINK_C_OBJ_FILES} \
#     ${LINK_ASM_OBJ_FILES} \
#     ${DEP_LIBS} \
#     -o /Users/biezhihua/StudySpace/libssplayer.so

echo "FFmpeg install success"
