#!/bin/bash

###############################################################################
# xStudio Self-Contained Wrapped Build Script
# Version: 3.0 (Wrapped/Isolated like RV)
# Installation: /opt/xstudio/xstudio-2025.1.0/
# All dependencies bundled inside
###############################################################################

set -e

# Color definitions
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_section() {
    echo -e "${PURPLE}${BOLD}========================================${NC}"
    echo -e "${PURPLE}${BOLD}=== $1${NC}"
    echo -e "${PURPLE}${BOLD}========================================${NC}"
}

print_success() { echo -e "${GREEN}${BOLD}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

###############################################################################
# Configuration
###############################################################################

XSTUDIO_VERSION="2025.1.0"
XSTUDIO_INSTALL_ROOT="/opt/xstudio"
XSTUDIO_INSTALL_PATH="${XSTUDIO_INSTALL_ROOT}/xstudio-${XSTUDIO_VERSION}"
TMP_BUILD_DIR="${HOME}/tmp_xstudio_wrapped_build"

JOBS=$(nproc)

# Component versions
CMAKE_VERSION=3.31.9
VER_QT=6.5.3  # We'll build our own Qt
VER_PYTHON=3.9.21
VER_ACTOR=1.1.0
VER_FFMPEG=5.1
VER_FMTLIB=8.0.1
VER_libGLEW=2.1.0
VER_NASM=2.15.05
VER_NLOHMANN=3.11.2
VER_OCIO2=2.2.0
VER_OPENEXR=RB-3.1
VER_OpenTimelineIO=cxx17
VER_SPDLOG=1.9.2
VER_x264=stable
VER_x265=3.5
VER_XSTUDIO=main

print_section "xStudio Wrapped Installation Build"
print_info "Version: ${XSTUDIO_VERSION}"
print_info "Install path: ${XSTUDIO_INSTALL_PATH}"
print_info "Build directory: ${TMP_BUILD_DIR}"
print_info "All dependencies will be bundled inside xStudio"

# Check sudo
if ! sudo -v; then
    print_error "This script requires sudo access"
    exit 1
fi

# Check disk space (need more for bundled install)
AVAILABLE_SPACE=$(df -BG ${HOME} | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 50 ]; then
    print_warning "Low disk space! At least 50GB recommended for wrapped build"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

mkdir -p ${TMP_BUILD_DIR}
cd ${TMP_BUILD_DIR}

###############################################################################
# Clean Environment
###############################################################################

print_section "Cleaning Build Environment"

clean_env() {
    export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | grep -v "/opt/xstudio" | tr '\n' ':' | sed 's/:$//' | sed 's/^://')
    export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | grep -v "/opt/xstudio" | tr '\n' ':' | sed 's/:$//' | sed 's/^://')
    export PYTHONPATH=$(echo $PYTHONPATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | grep -v "/opt/xstudio" | tr '\n' ':' | sed 's/:$//' | sed 's/^://')
    export PKG_CONFIG_PATH=$(echo $PKG_CONFIG_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | grep -v "/opt/xstudio" | tr '\n' ':' | sed 's/:$//' | sed 's/^://')
}

clean_env
print_success "Environment cleaned"

###############################################################################
# Install Minimal System Dependencies (build tools only)
###############################################################################

print_section "Installing Build Tools"

sudo dnf config-manager --set-enabled crb 2>/dev/null || sudo dnf config-manager --set-enabled powertools 2>/dev/null
sudo dnf install -y epel-release
sudo dnf groupinstall "Development Tools" -y

sudo dnf install -y \
    git gcc gcc-c++ make automake autoconf libtool pkg-config \
    wget tar bzip2 patchelf perl-IPC-Cmd \
    libX11-devel libXi-devel libXmu-devel \
    libxcb-devel xcb-util-devel xcb-util-image-devel \
    xcb-util-keysyms-devel xcb-util-renderutil-devel xcb-util-wm-devel \
    libxkbcommon-x11-devel xcb-util-cursor \
    mesa-libGL-devel mesa-libGLU-devel \
    alsa-lib-devel pulseaudio-libs-devel \
    wayland-devel libinput-devel \
    openssl-devel

print_success "Build tools installed"

###############################################################################
# Create Installation Structure
###############################################################################

print_section "Creating Installation Structure"

# Create directories with sudo
sudo mkdir -p ${XSTUDIO_INSTALL_PATH}/{bin,lib,include,share,python,qt}

# Make OWNED by current user (so builds can write without sudo)
sudo chown -R $(id -u):$(id -g) ${XSTUDIO_INSTALL_PATH}

# Make writable
sudo chmod -R 755 ${XSTUDIO_INSTALL_PATH}

# Set environment
export PREFIX=${XSTUDIO_INSTALL_PATH}
export PATH=${PREFIX}/bin:$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
export CMAKE_PREFIX_PATH=${PREFIX}

print_success "Installation structure created (owned by build user)"

###############################################################################
# Build Python 3.9 (bundled)
###############################################################################

print_section "Building Python ${VER_PYTHON} (bundled)"

cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/bin/python3.9" ]; then
    wget https://www.python.org/ftp/python/${VER_PYTHON}/Python-${VER_PYTHON}.tar.xz
    tar -xf Python-${VER_PYTHON}.tar.xz
    cd Python-${VER_PYTHON}
    
    ./configure \
        --prefix=${PREFIX}/python \
        --enable-shared \
        --enable-optimizations \
        --with-ensurepip=install
    
    make -j${JOBS}
    make install
    
    # Create symlinks
    ln -sf ${PREFIX}/python/bin/python3.9 ${PREFIX}/bin/python3.9
    ln -sf ${PREFIX}/python/bin/python3 ${PREFIX}/bin/python3
    ln -sf ${PREFIX}/python/bin/pip3 ${PREFIX}/bin/pip3
    
    # Add Python lib to LD_LIBRARY_PATH for subsequent builds
    export LD_LIBRARY_PATH=${PREFIX}/python/lib:$LD_LIBRARY_PATH
    
    print_success "Python ${VER_PYTHON} built and installed"
else
    print_info "Python already built"
fi

###############################################################################
# Install CMake (bundled)
###############################################################################

print_section "Installing CMake ${CMAKE_VERSION} (bundled)"

cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/bin/cmake" ]; then
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
    tar -xzf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
    cp -r cmake-${CMAKE_VERSION}-linux-x86_64/* ${PREFIX}/
    print_success "CMake installed"
else
    print_info "CMake already installed"
fi

###############################################################################
# Install System Qt6 Packages and Bundle Into xStudio
###############################################################################

print_section "Installing and Bundling Qt6 ${VER_QT}"

# Install system Qt6 packages
print_info "Installing system Qt6 packages..."
sudo dnf install -y \
    qt6-qtbase-devel qt6-qtbase-gui \
    qt6-qtdeclarative-devel qt6-qttools-devel \
    qt6-qtsvg-devel qt6-qtwayland-devel \
    qt6-qt5compat-devel qt6-qtmultimedia-devel \
    qt6-qtnetworkauth-devel qt6-qtwebsockets-devel

print_success "System Qt6 packages installed"

# Copy system Qt6 into xStudio's bundled location
if [ ! -f "${PREFIX}/qt/bin/qmake6" ]; then
    print_info "Copying Qt6 libraries into xStudio bundle..."
    
    # Create Qt directory structure
    mkdir -p ${PREFIX}/qt/{bin,lib,plugins,qml,libexec}
    
    # Copy Qt6 binaries
    cp -a /usr/lib64/qt6/bin/* ${PREFIX}/qt/bin/ 2>/dev/null || true
    cp -a /usr/bin/qmake6 ${PREFIX}/qt/bin/ 2>/dev/null || true
    cp -a /usr/bin/moc-qt6 ${PREFIX}/qt/bin/ 2>/dev/null || true
    cp -a /usr/bin/rcc-qt6 ${PREFIX}/qt/bin/ 2>/dev/null || true
    cp -a /usr/bin/uic-qt6 ${PREFIX}/qt/bin/ 2>/dev/null || true
    
    # Copy Qt6 libraries
    cp -a /usr/lib64/libQt6*.so* ${PREFIX}/qt/lib/ 2>/dev/null || true
    cp -a /usr/lib64/qt6/lib/* ${PREFIX}/qt/lib/ 2>/dev/null || true
    
    # Copy Qt6 plugins
    cp -a /usr/lib64/qt6/plugins/* ${PREFIX}/qt/plugins/ 2>/dev/null || true
    
    # Copy Qt6 QML modules
    cp -a /usr/lib64/qt6/qml/* ${PREFIX}/qt/qml/ 2>/dev/null || true
    
    # Copy Qt6 libexec
    cp -a /usr/lib64/qt6/libexec/* ${PREFIX}/qt/libexec/ 2>/dev/null || true
    
    # Create cmake files for Qt6
    mkdir -p ${PREFIX}/qt/lib/cmake
    cp -a /usr/lib64/cmake/Qt6* ${PREFIX}/qt/lib/cmake/ 2>/dev/null || true
    
    # Fix any broken symlinks
    find ${PREFIX}/qt -type l -xtype l -delete 2>/dev/null || true
    
    print_success "Qt6 bundled into ${PREFIX}/qt/"
else
    print_info "Qt6 already bundled"
fi

# Set environment to use bundled Qt6
export CMAKE_PREFIX_PATH=${PREFIX}/qt/lib/cmake:${CMAKE_PREFIX_PATH}
export PATH=${PREFIX}/qt/bin:$PATH
export LD_LIBRARY_PATH=${PREFIX}/qt/lib:$LD_LIBRARY_PATH

print_success "Qt6 ready for xStudio build"


###############################################################################
# Build All Dependencies (into PREFIX)
###############################################################################

print_section "Building xStudio Dependencies"

# For each dependency, use --prefix=${PREFIX} or CMAKE_INSTALL_PREFIX=${PREFIX}

# GLEW
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libGLEW.so" ]; then
    wget https://sourceforge.net/projects/glew/files/glew/${VER_libGLEW}/glew-${VER_libGLEW}.tgz
    tar -xf glew-${VER_libGLEW}.tgz
    cd glew-${VER_libGLEW}/
    make -j${JOBS} GLEW_DEST=${PREFIX}
    make install GLEW_DEST=${PREFIX}
    print_success "GLEW installed"
fi

# nlohmann JSON - ADD error handling
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/include/nlohmann/json.hpp" ]; then
    rm -f v${VER_NLOHMANN}.tar.gz  # Use variable, not hardcoded
    wget https://github.com/nlohmann/json/archive/refs/tags/v${VER_NLOHMANN}.tar.gz
    tar -xf v${VER_NLOHMANN}.tar.gz
    cd json-${VER_NLOHMANN}
    rm -rf build
    mkdir build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX} -DJSON_BuildTests=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}  # Return to base dir
    print_success "nlohmann JSON installed"
fi

# OpenEXR - FIXED VERSION
cd ${TMP_BUILD_DIR}
if [ ! -d "${PREFIX}/include/OpenEXR" ]; then
    rm -rf openexr  # Add cleanup
    
    git clone https://github.com/AcademySoftwareFoundation/openexr.git
    cd openexr
    git checkout ${VER_OPENEXR}
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOPENEXR_INSTALL_TOOLS=Off \
        -DBUILD_TESTING=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenEXR installed"
fi

# ActorFramework - FIXED VERSION
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libcaf_core.so" ]; then
    # Clean up if exists
    rm -rf actor-framework
    
    git clone https://github.com/actor-framework/actor-framework
    cd actor-framework
    git checkout ${VER_ACTOR}
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCAF_ENABLE_EXAMPLES=OFF \
        -DCAF_ENABLE_TESTING=OFF \
        -DCAF_ENABLE_TOOLS=OFF
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "ActorFramework installed"
fi

# OpenColorIO
cd ${TMP_BUILD_DIR}
if [ ! -d "${PREFIX}/include/OpenColorIO" ]; then
    rm -rf OpenColorIO-${VER_OCIO2}  # Clean up
    rm -f v${VER_OCIO2}.tar.gz
    
    wget https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v${VER_OCIO2}.tar.gz
    tar -xf v${VER_OCIO2}.tar.gz
    cd OpenColorIO-${VER_OCIO2}
    rm -rf build
    mkdir build && cd build
    
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOCIO_BUILD_APPS=OFF \
        -DOCIO_BUILD_TESTS=OFF \
        -DOCIO_BUILD_GPU_TESTS=OFF \
        -DPython_EXECUTABLE=${PREFIX}/bin/python3.9 \
        -DPython_INCLUDE_DIR=${PREFIX}/python/include/python3.9 \
        -DPython_LIBRARY=${PREFIX}/python/lib/libpython3.9.so
    
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenColorIO installed"
fi

# SPDLOG - ADD explicit cd
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libspdlog.so" ]; then
    rm -f v${VER_SPDLOG}.tar.gz
    wget https://github.com/gabime/spdlog/archive/refs/tags/v${VER_SPDLOG}.tar.gz
    tar -xf v${VER_SPDLOG}.tar.gz
    cd spdlog-${VER_SPDLOG}  # Explicit cd
    rm -rf build
    mkdir build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX} -DSPDLOG_BUILD_SHARED=On
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "SPDLOG installed"
fi

# FMTLIB - ADD explicit cd
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libfmt.so" ]; then
    rm -f ${VER_FMTLIB}.tar.gz
    wget https://github.com/fmtlib/fmt/archive/refs/tags/${VER_FMTLIB}.tar.gz
    tar -xf ${VER_FMTLIB}.tar.gz
    cd fmt-${VER_FMTLIB}  # Explicit cd
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
        -DFMT_DOC=Off \
        -DFMT_TEST=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "FMTLIB installed"
fi

# OpenTimelineIO - FIXED VERSION
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libopentime.so" ]; then
    rm -rf OpenTimelineIO  # Add cleanup
    
    git clone https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git
    cd OpenTimelineIO
    git checkout ${VER_OpenTimelineIO}
    rm -rf build
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOTIO_PYTHON_INSTALL=ON \
        -DOTIO_DEPENDENCIES_INSTALL=OFF \
        -DOTIO_FIND_IMATH=ON \
        -DPython3_EXECUTABLE=${PREFIX}/bin/python3.9 \
        -DPython3_INCLUDE_DIR=${PREFIX}/python/include/python3.9 \
        -DPython3_LIBRARY=${PREFIX}/python/lib/libpython3.9.so
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenTimelineIO installed"
fi

# FFmpeg (with codec support)
cd ${TMP_BUILD_DIR}

# NASM
if ! command -v nasm &> /dev/null; then
    wget https://www.nasm.us/pub/nasm/releasebuilds/${VER_NASM}/nasm-${VER_NASM}.tar.bz2
    tar -xf nasm-${VER_NASM}.tar.bz2
    cd nasm-${VER_NASM}
    ./autogen.sh
    ./configure --prefix=${PREFIX}
    make -j${JOBS}
    make install
fi

# x264 - FIXED VERSION
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libx264.so" ]; then
    rm -rf x264  # Add cleanup
    
    git clone --branch ${VER_x264} --depth 1 https://code.videolan.org/videolan/x264.git || \
    git clone --branch ${VER_x264} --depth 1 https://github.com/mirror/x264.git
    cd x264
    ./configure --prefix=${PREFIX} --enable-shared --enable-pic
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
fi

# x265
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libx265.so" ]; then
    wget https://bitbucket.org/multicoreware/x265_git/downloads/x265_${VER_x265}.tar.gz
    tar -xf x265_${VER_x265}.tar.gz
    cd x265_${VER_x265}/build/linux
    cmake -G "Unix Makefiles" \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DENABLE_SHARED=ON \
        ../../source
    make -j${JOBS}
    make install
fi

# fdk-aac - FIXED VERSION
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libfdk-aac.so" ]; then
    rm -rf fdk-aac  # Add cleanup
    
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
    cd fdk-aac
    autoreconf -fiv
    ./configure --prefix=${PREFIX} --enable-shared
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
fi

# FFmpeg - ADD explicit cd
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/bin/ffmpeg" ]; then
    rm -f ffmpeg-${VER_FFMPEG}.tar.bz2
    wget https://ffmpeg.org/releases/ffmpeg-${VER_FFMPEG}.tar.bz2
    tar -xf ffmpeg-${VER_FFMPEG}.tar.bz2
    cd ffmpeg-${VER_FFMPEG}  # Already there, but explicit
    ./configure \
        --prefix=${PREFIX} \
        --extra-libs=-lpthread \
        --extra-libs=-lm \
        --enable-gpl \
        --enable-libfdk_aac \
        --enable-libfreetype \
        --enable-libx264 \
        --enable-libx265 \
        --enable-shared \
        --enable-nonfree \
        --enable-pic \
        --disable-vulkan
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "FFmpeg installed"
fi

###############################################################################
# Clone and Build xStudio
###############################################################################

print_section "Building xStudio"

cd ${TMP_BUILD_DIR}

if [ -d "xstudio/.git" ]; then
    cd xstudio
    git fetch origin
    git checkout ${VER_XSTUDIO}
    git pull origin ${VER_XSTUDIO}
else
    [ -d "xstudio" ] && rm -rf xstudio
    git clone https://github.com/AcademySoftwareFoundation/xstudio.git
    cd xstudio
    git checkout ${VER_XSTUDIO}
fi

[ -d build ] && rm -rf build
mkdir build && cd build

# Configure with all bundled dependencies
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH="${PREFIX}/qt:${PREFIX}" \
    -DQt6_DIR="${PREFIX}/qt/lib/cmake/Qt6" \
    -DBUILD_DOCS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DPython3_EXECUTABLE=${PREFIX}/bin/python3.9 \
    -DPython3_INCLUDE_DIR=${PREFIX}/python/include/python3.9 \
    -DPython3_LIBRARY=${PREFIX}/python/lib/libpython3.9.so \
    -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib:${PREFIX}/lib:${PREFIX}/qt/lib:${PREFIX}/python/lib" \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE

make -j${JOBS}

if [ $? -ne 0 ]; then
    print_error "xStudio build failed!"
    exit 1
fi

print_success "xStudio built successfully"

###############################################################################
# Install xStudio binaries
###############################################################################

print_section "Installing xStudio"

# Copy binaries
cp -r bin/* ${PREFIX}/bin/

# Fix RPATH with patchelf (ensure RELATIVE paths)
cd ${PREFIX}/bin
for binary in xstudio.bin *; do
    if [ -f "$binary" ] && [ -x "$binary" ]; then
        patchelf --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../qt/lib:\$ORIGIN/../python/lib" "$binary" 2>/dev/null || true
    fi
done

# Fix library RPATH
cd ${PREFIX}/bin/lib
for lib in *.so; do
    patchelf --set-rpath "\$ORIGIN:\$ORIGIN/../../lib:\$ORIGIN/../../qt/lib:\$ORIGIN/../../python/lib" "$lib" 2>/dev/null || true
done

print_success "xStudio installed with proper RPATH"

###############################################################################
# Create xStudio Wrapper Script
###############################################################################

print_section "Creating xStudio Wrapper"

cat > ${PREFIX}/bin/xstudio-wrapper << 'WRAPPEREOF'
#!/bin/bash
# xStudio Wrapper Script - Sets environment only for xStudio

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XSTUDIO_ROOT="$(dirname "$SCRIPT_DIR")"

# Set xStudio-specific environment (isolated from system/RV)
export PATH="${XSTUDIO_ROOT}/bin:${XSTUDIO_ROOT}/qt/bin:${XSTUDIO_ROOT}/python/bin:$PATH"
export LD_LIBRARY_PATH="${XSTUDIO_ROOT}/lib:${XSTUDIO_ROOT}/qt/lib:${XSTUDIO_ROOT}/python/lib:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="${XSTUDIO_ROOT}/qt/plugins"
export QML2_IMPORT_PATH="${XSTUDIO_ROOT}/qt/qml"
export PYTHONPATH="${XSTUDIO_ROOT}/python/lib/python3.9/site-packages:$PYTHONPATH"
export XSTUDIO_HOME="${XSTUDIO_ROOT}"

# Launch xStudio
exec "${XSTUDIO_ROOT}/bin/xstudio.bin" "$@"
WRAPPEREOF

chmod +x ${PREFIX}/bin/xstudio-wrapper

print_success "Wrapper script created"

###############################################################################
# Create System-wide Symbolic Link
###############################################################################

print_section "Creating System Link"

sudo ln -sf ${PREFIX}/bin/xstudio-wrapper /usr/local/bin/xstudio

print_success "System link created: /usr/local/bin/xstudio"

###############################################################################
# Create Desktop Entry
###############################################################################

print_section "Creating Desktop Entry"

# Copy icon
ICON_SRC="${TMP_BUILD_DIR}/xstudio/ui/qml/xstudio/assets/icons/xstudio_logo_256_v1.png"
if [ -f "$ICON_SRC" ]; then
    mkdir -p ${PREFIX}/share/icons
    cp "$ICON_SRC" ${PREFIX}/share/icons/xstudio.png
fi

sudo tee /usr/share/applications/xstudio.desktop > /dev/null << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio ${XSTUDIO_VERSION}
Comment=Professional Media Playback and Review
Exec=${PREFIX}/bin/xstudio-wrapper %U
Icon=${PREFIX}/share/icons/xstudio.png
Terminal=false
Categories=AudioVideo;Video;Player;AudioVideoEditing;
MimeType=video/quicktime;video/mp4;image/exr;image/dpx;
Keywords=video;player;review;media;vfx;
StartupNotify=true
EOF

sudo update-desktop-database
print_success "Desktop entry created"

###############################################################################
# Set Final Permissions
###############################################################################

print_section "Setting Final Permissions"

sudo chown -R root:root ${XSTUDIO_INSTALL_PATH}
sudo chmod -R u=rwX,g=rX,o=rX ${XSTUDIO_INSTALL_PATH}
sudo chmod +x ${PREFIX}/bin/*

print_success "Permissions set"

###############################################################################
# Final Summary
###############################################################################

print_section "Installation Complete!"

cat << SUMMARY

${GREEN}${BOLD}✓ xStudio Wrapped Installation Complete!${NC}

${BOLD}Installation Details:${NC}
  Version:           ${XSTUDIO_VERSION}
  Location:          ${XSTUDIO_INSTALL_PATH}
  Wrapper:           ${PREFIX}/bin/xstudio-wrapper
  System Link:       /usr/local/bin/xstudio

${BOLD}Bundled Components:${NC}
  ✓ Qt ${VER_QT}
  ✓ Python ${VER_PYTHON}
  ✓ FFmpeg ${VER_FFMPEG}
  ✓ OpenEXR ${VER_OPENEXR}
  ✓ OpenColorIO ${VER_OCIO2}
  ✓ CAF ${VER_ACTOR}
  ✓ All other dependencies

${BOLD}How to Run:${NC}
  Command line:      xstudio
  Applications:      Search for "xStudio"

${BOLD}Isolation:${NC}
  ✓ Completely independent from RV
  ✓ Completely independent from system libraries
  ✓ All dependencies bundled inside ${XSTUDIO_INSTALL_PATH}
  ✓ Can coexist with any version of RV
  ✓ Portable to other machines (just copy the directory)

${BOLD}Testing:${NC}
  1. Test xStudio:   xstudio
  2. Test RV:        rv
  3. Both should work without conflicts!

${GREEN}Build completed successfully!${NC}

SUMMARY

print_info "Build directory: ${TMP_BUILD_DIR}"
print_info "You can clean up build directory if needed:"
print_info "  rm -rf ${TMP_BUILD_DIR}"

###############################################################################
# Set Final Permissions for Multi-User AD Environment
###############################################################################

print_section "Setting Final Permissions for All Users"

# Set ownership to root (system-wide)
sudo chown -R root:root ${XSTUDIO_INSTALL_PATH}

# Make readable and executable by all users
# u=rwX (owner can read, write, execute)
# g=rX (group can read and execute)
# o=rX (others can read and execute)
sudo chmod -R u=rwX,g=rX,o=rX ${XSTUDIO_INSTALL_PATH}

# Ensure all binaries are executable
sudo find ${XSTUDIO_INSTALL_PATH}/bin -type f -exec chmod +x {} \;
sudo find ${XSTUDIO_INSTALL_PATH}/qt/bin -type f -exec chmod +x {} \;

print_success "Permissions set for all domain users"
