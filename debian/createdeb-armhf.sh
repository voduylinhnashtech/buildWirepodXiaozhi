#!/bin/bash

# Build .deb cho armhf (ARM 32-bit hard-float) — tách khỏi createdeb.sh (arm64).
# Gói ra: final-armhf/wirepod_armhf-<version>.deb
# Thư mục staging: debcreate-armhf/ (không dùng chung debcreate/ với arm64).

#set -e

COMPILE_ARCHES=(armhf)

# Use wirepodxiaozhi-main repo
if [ -d "../../wirepodxiaozhi-main" ]; then
    WP_COMMIT_HASH=$(cd ../../wirepodxiaozhi-main && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    WP_COMMIT_HASH="github"
fi
GOLDFLAGS="-X 'github.com/kercre123/wire-pod/chipper/pkg/vars.CommitSHA=${WP_COMMIT_HASH}'"

ORIGPATH="$(pwd)"
DEBROOT="debcreate-armhf"
FINALDIR="final-armhf"
DEBCREATEPATH="$(pwd)/${DEBROOT}"
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/debfiles/go-sudo-path.sh"

# Clean cache and old builds before starting
echo "🧹 Cleaning Go cache and old builds..."
go clean -cache -modcache 2>/dev/null || true
rm -rf "${DEBROOT}" 2>/dev/null || true
echo "✅ Clean complete"

# Create symlink if not exists (for go.mod replace to work)
if [ ! -L "../wirepodxiaozhi" ]; then
    ln -sf ../../wirepodxiaozhi ../wirepodxiaozhi 2>/dev/null || true
    echo "✅ Symlink created"
fi

AMD64T="$(pwd)/wire-pod-toolchain/x86_64-unknown-linux-gnu/bin/x86_64-unknown-linux-gnu-"
ARMT="$(pwd)/wire-pod-toolchain/arm-unknown-linux-gnueabihf/bin/arm-unknown-linux-gnueabihf-"
ARM64T="$(pwd)/wire-pod-toolchain/aarch64-linux-gnu/bin/aarch64-linux-gnu-"

sudo apt update -y
#sudo apt upgrade -y
sudo apt install -y libopus-dev libogg-dev build-essential pkg-config gcc-arm-linux-gnueabihf libsodium-dev

# figure out arguments
if [[ $1 == "" ]]; then
    echo "You must provide a version. ex. 1.0.0"
    exit 1
fi

PODVERSION=$1
echo "Building version: $PODVERSION"

if [[ $PODVERSION == "main" ]]; then
    PODVERSION="1.0.0"
fi

# gather compilers
if [[ ! -d wire-pod-toolchain ]]; then
    git clone https://github.com/kercre123/wire-pod-toolchain --depth=1
fi

# compile vosk...

function createDEBIAN() {
    ARCH=$1
    mkdir -p ${DEBCREATEPATH}/${ARCH}/DEBIAN
    cp -rfp debfiles/postinst ${DEBCREATEPATH}/${ARCH}/DEBIAN/
    cp -rfp debfiles/postrm ${DEBCREATEPATH}/${ARCH}/DEBIAN/
    cp -rfp debfiles/preinst ${DEBCREATEPATH}/${ARCH}/DEBIAN/
    cp -rfp debfiles/prerm ${DEBCREATEPATH}/${ARCH}/DEBIAN/
    chmod 0775 ${DEBCREATEPATH}/${ARCH}/DEBIAN/*
    cd ${DEBCREATEPATH}/${ARCH}/DEBIAN
    echo "Package: wirepod" > control
    echo "Version: ${PODVERSION#v}" >> control
    echo "Maintainer: Kerigan Creighton <kerigancreighton@gmail.com>" >> control
    echo "Description: A replacement voice server for the Anki Vector robot." >> control
    echo "Homepage: https://github.com/haryken/wirepodxiaozhi" >> control
    echo "Architecture: $ARCH" >> control
    echo "Depends: libopus0, libogg0, avahi-daemon, libatomic1, libsodium23" >> control
    cd $ORIGPATH
}

function doLibSodium() {
    ARCH=$1
    cd $ORIGPATH
    if [[ ! -f built/${ARCH}/sodium_built ]]; then
        mkdir -p build/${ARCH}
        mkdir -p built/${ARCH}
        BUILTDIR="$(pwd)/built/${ARCH}"
        cd build/${ARCH}
        git clone https://github.com/jedisct1/libsodium.git
        cd libsodium
        git checkout 1.0.18
        expToolchain $ARCH
        ./autogen.sh -s
        ./configure --host=$PODHOST --prefix="$BUILTDIR"
        make -j6
        make install
        touch ${BUILTDIR}/sodium_built
    fi
}

function prepareVOSKbuild_AMD64() {
    cd $ORIGPATH
    ARCH=amd64
    mkdir -p build/${ARCH}
    mkdir -p built/${ARCH}
    KALDIROOT="$(pwd)/build/${ARCH}/kaldi"
    BPREFIX="$(pwd)/built/${ARCH}"
    cd build/${ARCH}
    export CC=${AMD64T}gcc
    export CXX=${AMD64T}g++
    export LD=${AMD64T}ld
    export AR=${AMD64T}ar
    export FORTRAN=${AMD64T}gfortran
    export RANLIB=${AMD64T}ranlib
    export AS=${AMD64T}as
    export CPP=${AMD64T}cpp
    export PODHOST=x86_64-unknown-linux-gnu
    if [[ ! -f ${KALDIROOT}/KALDIBUILT ]]; then
        git clone -b vosk --single-branch https://github.com/alphacep/kaldi
        cd kaldi/tools
        git clone -b v0.3.20 --single-branch https://github.com/xianyi/OpenBLAS
        git clone -b v3.2.1  --single-branch https://github.com/alphacep/clapack
        make -C OpenBLAS ONLY_CBLAS=1 DYNAMIC_ARCH=1 TARGET=NEHALEM USE_LOCKING=1 USE_THREAD=0 all
        make -C OpenBLAS PREFIX=$(pwd)/OpenBLAS/install install
        mkdir -p clapack/BUILD && cd clapack/BUILD && cmake .. && make -j 8 && find . -name "*.a" | xargs cp -t ../../OpenBLAS/install/lib
        cd ${KALDIROOT}/tools
        git clone --single-branch https://github.com/alphacep/openfst openfst
        cd openfst
        autoreconf -i
        CFLAGS="-g -O3" ./configure --prefix=${KALDIROOT}/tools/openfst --host=$PODHOST --enable-static --enable-shared --enable-far --enable-ngram-fsts --enable-lookahead-fsts --with-pic --disable-bin
        make -j 8 && make install
        cd ${KALDIROOT}/src
        ./configure --mathlib=OPENBLAS_CLAPACK --shared --use-cuda=no --host=$PODHOST
        sed -i 's:-msse -msse2:-msse -msse2:g' kaldi.mk
        sed -i 's: -O1 : -O3 :g' kaldi.mk
        make -j 8 online2 lm rnnlm
        touch ${KALDIROOT}/KALDIBUILT
        find ${KALDIROOT} -name "*.o" -exec rm {} \;
    fi
    cd $ORIGPATH
}

function prepareVOSKbuild_ARMARM64() {
    cd $ORIGPATH
    ARCH=$1
    if [[ ${ARCH} == "amd64" ]]; then
        echo "prepareVOSKbuild_ARMARM64: this function is for armhf and arm64 only."
        exit 1
    fi
    mkdir -p build/${ARCH}
    mkdir -p built/${ARCH}
    KALDIROOT="$(pwd)/build/${ARCH}/kaldi"
    BPREFIX="$(pwd)/built/${ARCH}"
    cd build/${ARCH}
    expToolchain ${ARCH}
    if [[ ! -f ${KALDIROOT}/KALDIBUILT ]]; then
        git clone -b vosk --single-branch https://github.com/alphacep/kaldi
        cd kaldi/tools
        git clone -b v0.3.20 --single-branch https://github.com/xianyi/OpenBLAS
        git clone -b v3.2.1  --single-branch https://github.com/alphacep/clapack
        echo ${OPENBLAS_ARGS}
        if [[ $ARCH == "armhf" ]]; then
            make -C OpenBLAS ONLY_CBLAS=1 TARGET=ARMV7 ${OPENBLAS_ARGS} HOSTCC=/usr/bin/gcc USE_LOCKING=1 USE_THREAD=0 all
            elif [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
            make -C OpenBLAS ONLY_CBLAS=1 TARGET=ARMV8 ${OPENBLAS_ARGS} HOSTCC=/usr/bin/gcc USE_LOCKING=1 USE_THREAD=0 all
        fi
        make -C OpenBLAS ${OPENBLAS_ARGS} HOSTCC=gcc USE_LOCKING=1 USE_THREAD=0 PREFIX=$(pwd)/OpenBLAS/install install
        rm -rf clapack/BUILD
        mkdir -p clapack/BUILD && cd clapack/BUILD
        cmake -DCMAKE_C_FLAGS="$ARCHFLAGS" -DCMAKE_C_COMPILER_TARGET=$PODHOST \
        -DCMAKE_C_COMPILER=$CC -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_AR=$AR \
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
        -DCMAKE_CROSSCOMPILING=True ..
        make HOSTCC=gcc -j 10 -C F2CLIBS
        make  HOSTCC=gcc -j 10 -C BLAS
        make HOSTCC=gcc  -j 10 -C SRC
        find . -name "*.a" | xargs cp -t ../../OpenBLAS/install/lib
        cd ${KALDIROOT}/tools
        git clone --single-branch https://github.com/alphacep/openfst openfst
        cd openfst
        autoreconf -i
        CFLAGS="-g -O3" ./configure --prefix=${KALDIROOT}/tools/openfst --enable-static --enable-shared --enable-far --enable-ngram-fsts --enable-lookahead-fsts --with-pic --disable-bin --host=${CROSS_TRIPLE} --build=x86-linux-gnu
        make -j 8 && make install
        cd ${KALDIROOT}/src
        sed -i "s:TARGET_ARCH=\"\`uname -m\`\":TARGET_ARCH=$(echo $CROSS_TRIPLE|cut -d - -f 1):g" configure
        sed -i "s: -O1 : -O3 :g" makefiles/linux_openblas_arm.mk
        ./configure --mathlib=OPENBLAS_CLAPACK --shared --use-cuda=no
        make -j 8 online2 lm rnnlm
        find ${KALDIROOT} -name "*.o" -exec rm {} \;
        touch ${KALDIROOT}/KALDIBUILT
    else
        echo "VOSK dependencies already built for $ARCH"
    fi
    cd $ORIGPATH
}

function expToolchain() {
    ARCH=$1
    if [[ $ARCH == "amd64" ]]; then
        export CC=${AMD64T}gcc
        export CXX=${AMD64T}g++
        export LD=${AMD64T}ld
        export AR=${AMD64T}ar
        export FC=${AMD64T}gfortran
        export RANLIB=${AMD64T}ranlib
        export AS=${AMD64T}as
        export CPP=${AMD64T}cpp
        export PODHOST=x86_64-unknown-linux-gnu
        export CROSS_TRIPLE=${PODHOST}
        export CROSS_COMPILE=${AMD64T}
        export GOARCH=amd64
        elif [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
        export CC=${ARM64T}gcc
        export CXX=${ARM64T}g++
        export LD=${ARM64T}ld
        export AR=${ARM64T}ar
        export FC=${ARM64T}gfortran
        export RANLIB=${ARM64T}ranlib
        export AS=${ARM64T}as
        export CPP=${ARM64T}cpp
        export PODHOST=aarch64-linux-gnu
        export CROSS_TRIPLE=${PODHOST}
        export CROSS_COMPILE=${ARM64T}
        export GOARCH=arm64
        export GOARM=""
        export GOOS=linux
        export ARCHFLAGS=""
        elif [[ $ARCH == "armhf" ]]; then
        export CC=${ARMT}gcc
        export CXX=${ARMT}g++
        export LD=${ARMT}ld
        export AR=${ARMT}ar
        export FC=${ARMT}gfortran
        export RANLIB=${ARMT}ranlib
        export AS=${ARMT}as
        export CPP=${ARMT}cpp
        export PODHOST=arm-unknown-linux-gnueabihf
        export CROSS_TRIPLE=${PODHOST}
        export CROSS_COMPILE=${ARMT}
        export GOARCH=arm
        export GOARM=7
        export GOOS=linux
        export ARCHFLAGS="-mfloat-abi=hard -mfpu=neon-vfpv4"
    else
        echo "ERROR, Unknown arch: $ARCH"
        exit 1
    fi
}

function doVOSKbuild() {
    ARCH=$1
    cd $ORIGPATH
    KALDIROOT="$(pwd)/build/${ARCH}/kaldi"
    BPREFIX="$(pwd)/built/${ARCH}"
    if [[ ! -f ${BPREFIX}/lib/libvosk.so ]]; then
        cd build/${ARCH}
        expToolchain $ARCH
        if [[ ! -d vosk-api ]]; then
            git clone https://github.com/alphacep/vosk-api --depth=1
        fi
        cd vosk-api/src
        KALDI_ROOT=$KALDIROOT make EXTRA_LDFLAGS="-static-libstdc++" -j8
        cd "${ORIGPATH}/build/${ARCH}"
        mkdir -p "${BPREFIX}/lib"
        mkdir -p "${BPREFIX}/include"
        cp vosk-api/src/libvosk.so "${BPREFIX}/lib/"
        cp vosk-api/src/vosk_api.h "${BPREFIX}/include/"
    else
        echo "VOSK already built for $ARCH"
    fi
    cd $ORIGPATH
}

# Cross "make install" sometimes leaves libfoo.so as plain text stubs instead of symlinks
# (ld then says "file format not recognized; treating as linker script"). Recreate from SONAME.
function repairCrossBuiltSharedLinks() {
    local libdir="$1"
    [[ -d "$libdir" ]] || return 0
    local f soname base
    while IFS= read -r -d '' f; do
        file -b "$f" 2>/dev/null | grep -q 'ELF.*shared object' || continue
        [[ "$(basename "$f")" =~ \.so\.[0-9]+\.[0-9]+ ]] || continue
        soname=$(readelf -d "$f" 2>/dev/null | sed -n 's/.*Library soname: \[\(.*\)\]/\1/p')
        [[ -z "$soname" ]] && soname=$(readelf -d "$f" 2>/dev/null | sed -n 's/.*SONAME.*\[\(.*\)\]/\1/p')
        [[ -n "$soname" ]] || continue
        ln -sf "$(basename "$f")" "$libdir/$soname"
        base=$(echo "$soname" | sed -n 's/^\(lib[a-z0-9_-]*\)\.so\..*/\1/p')
        [[ -n "$base" ]] || continue
        ln -sf "$soname" "$libdir/${base}.so"
    done < <(find "$libdir" -maxdepth 1 -type f -name 'lib*.so.*' -print0 | sort -z -V)
}

function buildOPUS() {
    ARCH=$1
    cd $ORIGPATH
    BPREFIX="$(pwd)/built/${ARCH}"
    expToolchain $ARCH
    if [[ ! -f built/${ARCH}/ogg_built ]]; then
        cd build/${ARCH}
        rm -rf ogg
        git clone https://github.com/xiph/ogg --depth=1
        cd ogg
        ./autogen.sh
        ./configure --host=${PODHOST} --prefix=$BPREFIX
        make -j8
        make install
        cd $ORIGPATH
        touch built/${ARCH}/ogg_built
    else
        echo "OGG already built for $ARCH"
    fi

    if [[ ! -f built/${ARCH}/opus_built ]]; then
        cd build/${ARCH}
        rm -rf opus
        git clone https://github.com/xiph/opus --depth=1
        cd opus
        ./autogen.sh
        ./configure --host=${PODHOST} --prefix=$BPREFIX
        make -j8
        make install
        cd $ORIGPATH
        touch built/${ARCH}/opus_built
    else
        echo "OPUS already built for $ARCH"
    fi

    repairCrossBuiltSharedLinks "$BPREFIX/lib"
}

function buildWirePod() {
    ARCH=$1
    cd $ORIGPATH

    # get the webroot, intent data, certs
    # Use wirepodxiaozhi-main or wirepodxiaozhi repo
    if [ -d "../../wirepodxiaozhi-main" ]; then
        WPC=../../wirepodxiaozhi-main/chipper
        VCC=../../wirepodxiaozhi-main/vector-cloud
    elif [ -d "../../wirepodxiaozhi" ]; then
        WPC=../../wirepodxiaozhi/chipper
        VCC=../../wirepodxiaozhi/vector-cloud
    else
        echo "Error: wirepodxiaozhi-main or wirepodxiaozhi directory not found!"
        exit 1
    fi
    DC=${DEBROOT}/${ARCH}
    mkdir -p $DC/etc/wire-pod
    mkdir -p $DC/usr/bin
    mkdir -p $DC/usr/lib
    mkdir -p $DC/usr/include
    mkdir -p $DC/lib/systemd/system
    mkdir -p ${DEBROOT}/${ARCH}
    cp -rf $WPC/intent-data $DC/etc/wire-pod/
    cp -rf $WPC/epod $DC/etc/wire-pod/
    cp -rf $WPC/webroot $DC/etc/wire-pod/
    cp -rf $WPC/weather-map.json $DC/etc/wire-pod/
    cp -rf $VCC/pod-bot-install.sh $DC/etc/wire-pod/
    cp -rf $WPC/stttest.pcm $DC/etc/wire-pod/
    echo $PODVERSION > $DC/etc/wire-pod/version
    if [ ! -r "$DC/etc/wire-pod/webroot/index.html" ]; then
        echo "ERROR: webroot not packaged (missing $DC/etc/wire-pod/webroot/index.html). Check WPC=$WPC"
        exit 1
    fi
    # SKIP VOSK - not needed
    #cp -rf built/$ARCH/lib/libvosk.so $DC/usr/lib/
    #cp -rf built/$ARCH/include/vosk_api.h $DC/usr/include/
    cp -rf debfiles/wire-pod.service $DC/lib/systemd/system/
    cp -rf debfiles/config.ini $DC/etc/wire-pod/

    # BUILD WIREPOD
    expToolchain $ARCH

    export CGO_ENABLED=1
    export CGO_LDFLAGS="-L$(pwd)/built/$ARCH/lib -latomic"
    export CGO_CFLAGS="-I$(pwd)/built/$ARCH/include"
    if ! go build \
    -tags nolibopusfile,inbuiltble,novosk \
    -ldflags "-w -s ${GOLDFLAGS}" \
    -o $DC/usr/bin/wire-pod \
    ./pod/*.go; then
        echo "ERROR: go build failed for armhf."
        exit 1
    fi
    if [[ ! -s "$DC/usr/bin/wire-pod" ]]; then
        echo "ERROR: $DC/usr/bin/wire-pod missing or empty after go build."
        exit 1
    fi

    # CGO links sodium from built/armhf (SONAME e.g. libsodium.so.28); many boards only ship libsodium.so.23.
    mkdir -p "$DC/usr/lib/wire-pod/bundled"
    shopt -s nullglob
    for f in "$(pwd)/built/$ARCH/lib"/libsodium.so*; do
        [[ "$f" == *.la ]] && continue
        [[ "$f" == *.a ]] && continue
        [[ -e "$f" ]] || continue
        cp -a "$f" "$DC/usr/lib/wire-pod/bundled/"
    done
    shopt -u nullglob
    if ! ls "$DC/usr/lib/wire-pod/bundled"/libsodium.so.*.[0-9]* &>/dev/null; then
        echo "ERROR: no libsodium shared library copied to bundled/ — check built/$ARCH/lib and repairCrossBuiltSharedLinks."
        exit 1
    fi
    # Prefer bundled sodium at runtime (must be under [Service])
    sed -i '/^WorkingDirectory=\/etc\/wire-pod$/a Environment=LD_LIBRARY_PATH=/usr/lib/wire-pod/bundled' \
        "$DC/lib/systemd/system/wire-pod.service"
}

function finishDeb() {
    ARCH=$1
    mkdir -p $ORIGPATH/${FINALDIR}
    cd $ORIGPATH/${DEBROOT}
    dpkg-deb -Zxz --build $ARCH
    if ! dpkg-deb -c ${ARCH}.deb | grep -q 'usr/bin/wire-pod'; then
        echo "ERROR: ${ARCH}.deb does not contain usr/bin/wire-pod — packaging bug."
        exit 1
    fi
    mv $ARCH.deb ../${FINALDIR}/wirepod_$ARCH-$PODVERSION.deb
    cd $ORIGPATH
    echo "${FINALDIR}/wirepod_$ARCH-$PODVERSION.deb created successfully"
}

function prepareVOSKbuild() {
    ARCH=$1
    if [[ $ARCH == "armhf" ]] || [[ $ARCH == "arm64" ]]; then
        prepareVOSKbuild_ARMARM64 $ARCH
        elif [[ $ARCH == "amd64" ]]; then
        prepareVOSKbuild_AMD64
    else
        echo "Error: unknown architecture: $ARCH"
    fi
}

# start actually doing things


for arch in "${COMPILE_ARCHES[@]}"; do
    cd $ORIGPATH
    #    echo "Creating DEBIAN folder for $arch"
    createDEBIAN "$arch"
    doLibSodium "$arch"
    # SKIP VOSK - not needed
    #if [[ ! -f ${ORIGPATH}/built/$arch/lib/libvosk.so ]]; then
    #    echo "Compiling VOSK dependencies for $arch"
    #    prepareVOSKbuild "$arch"
    #fi
    #    echo "Building VOSK for $arch (if needed)"
    #doVOSKbuild "$arch"
    #    echo "Building OPUS for $arch (if needed)"
    buildOPUS "$arch"
    echo "Dependencies complete for $arch."
    echo "Building wire-pod for $arch..."
    #go clean -cache
    buildWirePod "$arch"
    echo "Finishing deb for $arch"
    finishDeb "$arch"
done

echo
echo "All debs are complete."
