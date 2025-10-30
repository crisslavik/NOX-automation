#!/bin/bash

###############################################################################
# xStudio Self-Contained Build Script - Production Version
# Version: 4.0 (System Qt6 + Bundled Dependencies)
# Updated: 2025-10-30
# Installation: /opt/xstudio/xstudio-2025.1.0/
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

print_section "xStudio Production Build Script"
print_info "Version: ${XSTUDIO_VERSION}"
print_info "Install path: ${XSTUDIO_INSTALL_PATH}"
print_info "Build directory: ${TMP_BUILD_DIR}"
print_info "Python module: ENABLED"
print_info "Qt6: System packages (via dnf)"

# Check sudo
if ! sudo -v; then
    print_error "This script requires sudo access"
    exit 1
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG ${HOME} | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 50 ]; then
    print_warning "Low disk space! At least 50GB recommended"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

mkdir -p ${TMP_BUILD_DIR}
cd ${TMP_BUILD_DIR}

###############################################################################
# Configure SELinux
###############################################################################

print_section "Configuring SELinux"

if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" != "Permissive" ] && [ "$SELINUX_STATUS" != "Disabled" ]; then
        print_info "Setting SELinux to permissive mode..."
        sudo setenforce 0
        
        # Make permanent
        if grep -q "^SELINUX=enforcing" /etc/selinux/config; then
            sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
            print_success "SELinux set to permissive (permanent)"
        fi
    else
        print_info "SELinux already in permissive/disabled mode"
    fi
else
    print_info "SELinux not found, skipping"
fi

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
# Install System Dependencies
###############################################################################

print_section "Installing System Dependencies"

sudo dnf config-manager --set-enabled crb 2>/dev/null || sudo dnf config-manager --set-enabled powertools 2>/dev/null
sudo dnf install -y epel-release
sudo dnf groupinstall "Development Tools" -y

# Build tools and libraries
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
    openssl-devel libuuid-devel

# System Qt6 packages
print_info "Installing system Qt6 packages..."
sudo dnf install -y \
    qt6-qtbase-devel qt6-qtbase-gui \
    qt6-qtdeclarative-devel qt6-qttools-devel \
    qt6-qtsvg-devel qt6-qtwayland-devel \
    qt6-qt5compat-devel qt6-qtmultimedia-devel \
    qt6-qtnetworkauth-devel qt6-qtwebsockets-devel

print_success "System dependencies installed"

###############################################################################
# Create Installation Structure
###############################################################################

print_section "Creating Installation Structure"

sudo mkdir -p ${XSTUDIO_INSTALL_PATH}/{bin,lib,lib64,include,share,python}
sudo chown -R $(id -u):$(id -g) ${XSTUDIO_INSTALL_PATH}
sudo chmod -R 755 ${XSTUDIO_INSTALL_PATH}

export PREFIX=${XSTUDIO_INSTALL_PATH}
export PATH=${PREFIX}/bin:$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:/usr/lib64/pkgconfig:$PKG_CONFIG_PATH
export CMAKE_PREFIX_PATH=${PREFIX}

print_success "Installation structure created"

###############################################################################
# Build Python 3.9 (bundled)
###############################################################################

print_section "Building Python ${VER_PYTHON}"

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
    
    ln -sf ${PREFIX}/python/bin/python3.9 ${PREFIX}/bin/python3.9
    ln -sf ${PREFIX}/python/bin/python3 ${PREFIX}/bin/python3
    ln -sf ${PREFIX}/python/bin/pip3 ${PREFIX}/bin/pip3
    
    export LD_LIBRARY_PATH=${PREFIX}/python/lib:$LD_LIBRARY_PATH
    
    print_success "Python ${VER_PYTHON} installed"
else
    print_info "Python already installed"
fi

###############################################################################
# Install CMake (bundled)
###############################################################################

print_section "Installing CMake ${CMAKE_VERSION}"

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
# Build Dependencies
###############################################################################

print_section "Building Dependencies"

# GLEW
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libGLEW.so" ]; then
    wget https://sourceforge.net/projects/glew/files/glew/${VER_libGLEW}/glew-${VER_libGLEW}.tgz
    tar -xf glew-${VER_libGLEW}.tgz
    cd glew-${VER_libGLEW}/
    make -j${JOBS} GLEW_DEST=${PREFIX}
    make install GLEW_DEST=${PREFIX}
    cd ${TMP_BUILD_DIR}
    print_success "GLEW installed"
fi

# nlohmann JSON
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/include/nlohmann/json.hpp" ]; then
    rm -f v${VER_NLOHMANN}.tar.gz
    wget https://github.com/nlohmann/json/archive/refs/tags/v${VER_NLOHMANN}.tar.gz
    tar -xf v${VER_NLOHMANN}.tar.gz
    cd json-${VER_NLOHMANN}
    rm -rf build
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX} -DJSON_BuildTests=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "nlohmann JSON installed"
fi

# OpenEXR
cd ${TMP_BUILD_DIR}
if [ ! -d "${PREFIX}/include/OpenEXR" ]; then
    rm -rf openexr
    git clone https://github.com/AcademySoftwareFoundation/openexr.git
    cd openexr
    git checkout ${VER_OPENEXR}
    rm -rf build
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOPENEXR_INSTALL_TOOLS=Off \
        -DBUILD_TESTING=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenEXR installed"
fi

# ActorFramework
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib64/libcaf_core.so" ]; then
    rm -rf actor-framework
    git clone https://github.com/actor-framework/actor-framework
    cd actor-framework
    git checkout ${VER_ACTOR}
    rm -rf build
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. \
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
    rm -rf OpenColorIO-${VER_OCIO2}
    rm -f v${VER_OCIO2}.tar.gz
    wget https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v${VER_OCIO2}.tar.gz
    tar -xf v${VER_OCIO2}.tar.gz
    cd OpenColorIO-${VER_OCIO2}
    rm -rf build
    mkdir build && cd build
    
    export Python_ROOT_DIR=${PREFIX}/python
    export Python3_ROOT_DIR=${PREFIX}/python
    
    ${PREFIX}/bin/cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOCIO_BUILD_APPS=OFF \
        -DOCIO_BUILD_TESTS=OFF \
        -DOCIO_BUILD_GPU_TESTS=OFF \
        -DPython_ROOT_DIR=${PREFIX}/python \
        -DPython3_ROOT_DIR=${PREFIX}/python
    
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenColorIO installed"
fi

# SPDLOG
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib64/libspdlog.so" ]; then
    rm -f v${VER_SPDLOG}.tar.gz
    wget https://github.com/gabime/spdlog/archive/refs/tags/v${VER_SPDLOG}.tar.gz
    tar -xf v${VER_SPDLOG}.tar.gz
    cd spdlog-${VER_SPDLOG}
    rm -rf build
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX} -DSPDLOG_BUILD_SHARED=On
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "SPDLOG installed"
fi

# FMTLIB
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib64/libfmt.so" ]; then
    rm -f ${VER_FMTLIB}.tar.gz
    wget https://github.com/fmtlib/fmt/archive/refs/tags/${VER_FMTLIB}.tar.gz
    tar -xf ${VER_FMTLIB}.tar.gz
    cd fmt-${VER_FMTLIB}
    rm -rf build
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
        -DFMT_DOC=Off \
        -DFMT_TEST=Off
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "FMTLIB installed"
fi

# NASM
cd ${TMP_BUILD_DIR}
if ! command -v ${PREFIX}/bin/nasm &> /dev/null; then
    wget https://www.nasm.us/pub/nasm/releasebuilds/${VER_NASM}/nasm-${VER_NASM}.tar.bz2
    tar -xf nasm-${VER_NASM}.tar.bz2
    cd nasm-${VER_NASM}
    ./autogen.sh
    ./configure --prefix=${PREFIX}
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "NASM installed"
fi

# x264
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libx264.so" ]; then
    rm -rf x264
    git clone --branch ${VER_x264} --depth 1 https://code.videolan.org/videolan/x264.git || \
    git clone --branch ${VER_x264} --depth 1 https://github.com/mirror/x264.git
    cd x264
    ./configure --prefix=${PREFIX} --enable-shared --enable-pic
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "x264 installed"
fi

# x265
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libx265.so" ]; then
    wget https://bitbucket.org/multicoreware/x265_git/downloads/x265_${VER_x265}.tar.gz
    tar -xf x265_${VER_x265}.tar.gz
    cd x265_${VER_x265}/build/linux
    ${PREFIX}/bin/cmake -G "Unix Makefiles" \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DENABLE_SHARED=ON \
        ../../source
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "x265 installed"
fi

# fdk-aac
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/libfdk-aac.so" ]; then
    rm -rf fdk-aac
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
    cd fdk-aac
    autoreconf -fiv
    ./configure --prefix=${PREFIX} --enable-shared
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "fdk-aac installed"
fi

# Freetype
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/lib/pkgconfig/freetype2.pc" ]; then
    wget https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.gz
    tar -xf freetype-2.13.2.tar.gz
    cd freetype-2.13.2
    ./configure --prefix=${PREFIX}
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "Freetype installed"
fi

# FFmpeg
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/bin/ffmpeg" ]; then
    rm -f ffmpeg-${VER_FFMPEG}.tar.bz2
    wget https://ffmpeg.org/releases/ffmpeg-${VER_FFMPEG}.tar.bz2
    tar -xf ffmpeg-${VER_FFMPEG}.tar.bz2
    cd ffmpeg-${VER_FFMPEG}
    
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

# pybind11
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/include/pybind11/pybind11.h" ]; then
    git clone https://github.com/pybind/pybind11.git
    cd pybind11
    git checkout v2.11.1
    mkdir build && cd build
    ${PREFIX}/bin/cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX}
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "pybind11 installed"
fi

# OpenTimelineIO
cd ${TMP_BUILD_DIR}
if [ ! -f "${PREFIX}/python/opentimelineio/libopentimelineio.so" ]; then
    rm -rf OpenTimelineIO
    git clone https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git
    cd OpenTimelineIO
    git checkout ${VER_OpenTimelineIO}
    rm -rf build
    mkdir build && cd build
    
    export Python_ROOT_DIR=${PREFIX}/python
    export Python3_ROOT_DIR=${PREFIX}/python
    
    ${PREFIX}/bin/cmake .. \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DOTIO_PYTHON_INSTALL=ON \
        -DOTIO_DEPENDENCIES_INSTALL=OFF \
        -DOTIO_FIND_IMATH=ON \
        -DPython_ROOT_DIR=${PREFIX}/python \
        -DPython3_ROOT_DIR=${PREFIX}/python
    
    make -j${JOBS}
    make install
    cd ${TMP_BUILD_DIR}
    print_success "OpenTimelineIO installed"
fi

###############################################################################
# Build and Install xStudio
###############################################################################

print_section "Building xStudio with Python Module"

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

export Python_ROOT_DIR=${PREFIX}/python
export Python3_ROOT_DIR=${PREFIX}/python
export LD_LIBRARY_PATH=${PREFIX}/python/lib:$LD_LIBRARY_PATH

print_info "Configuring xStudio..."

${PREFIX}/bin/cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH="/usr/lib64/cmake/Qt6:${PREFIX}" \
    -DQt6_DIR="/usr/lib64/cmake/Qt6" \
    -DBUILD_DOCS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_PYTHON_MODULE=ON \
    -DPython_ROOT_DIR=${PREFIX}/python \
    -DPython3_ROOT_DIR=${PREFIX}/python \
    -DPython3_EXECUTABLE=${PREFIX}/bin/python3.9 \
    -DPython3_INCLUDE_DIR=${PREFIX}/python/include/python3.9 \
    -DPython3_LIBRARY=${PREFIX}/python/lib/libpython3.9.so \
    -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib:/usr/lib64/qt6/lib:/usr/lib64:${PREFIX}/lib:${PREFIX}/python/lib" \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE

if [ $? -ne 0 ]; then
    print_error "xStudio configuration failed!"
    exit 1
fi

print_success "xStudio configured"
print_info "Building xStudio (this may take 15-30 minutes)..."

make -j${JOBS}

if [ $? -ne 0 ]; then
    print_error "xStudio build failed!"
    exit 1
fi

print_success "xStudio compiled successfully"

# Install using make install
print_info "Installing xStudio..."
sudo make install

# Copy Python modules
sudo cp -r bin/python/* ${PREFIX}/bin/python/ 2>/dev/null || true

# Copy bundled libraries to lib and lib64
print_info "Copying bundled libraries..."
sudo cp -a ${PREFIX}/lib64/*.so* ${PREFIX}/lib/ 2>/dev/null || true

print_success "xStudio installed"

###############################################################################
# Create xStudio Wrapper Script
###############################################################################

print_section "Creating xStudio Wrapper"

sudo tee ${PREFIX}/bin/xstudio-wrapper > /dev/null << 'WRAPPEREOF'
#!/bin/bash
# xStudio Wrapper - Production Version

# Set xStudio environment
export XSTUDIO_ROOT="/opt/xstudio/xstudio-2025.1.0/share/xstudio"
export PATH="/opt/xstudio/xstudio-2025.1.0/bin:$PATH"
export LD_LIBRARY_PATH="/opt/xstudio/xstudio-2025.1.0/python/opentimelineio:/opt/xstudio/xstudio-2025.1.0/lib64:/opt/xstudio/xstudio-2025.1.0/lib:/opt/xstudio/xstudio-2025.1.0/bin/lib:/usr/lib64/qt6/lib:/usr/lib64:/opt/xstudio/xstudio-2025.1.0/python/lib:${LD_LIBRARY_PATH}"
export PYTHONPATH="/opt/xstudio/xstudio-2025.1.0/bin/python/lib/python3.9/site-packages:/opt/xstudio/xstudio-2025.1.0/python:${PYTHONPATH}"
export QT_PLUGIN_PATH="/usr/lib64/qt6/plugins"
export QML2_IMPORT_PATH="/usr/lib64/qt6/qml"

# Launch xStudio
exec "/opt/xstudio/xstudio-2025.1.0/bin/xstudio.bin" "$@"
WRAPPEREOF

sudo chmod +x ${PREFIX}/bin/xstudio-wrapper

print_success "Wrapper created"

###############################################################################
# Create System Link
###############################################################################

print_section "Creating System Link"

sudo ln -sf ${PREFIX}/bin/xstudio-wrapper /usr/local/bin/xstudio

print_success "System link created"

###############################################################################
# Create Desktop Entry
###############################################################################

print_section "Creating Desktop Entry"

sudo mkdir -p ${PREFIX}/share/icons

ICON_SRC="${TMP_BUILD_DIR}/xstudio/ui/qml/xstudio/assets/icons/xstudio_logo_256_v1.png"
if [ -f "$ICON_SRC" ]; then
    sudo cp "$ICON_SRC" ${PREFIX}/share/icons/xstudio.png
fi

sudo tee /usr/share/applications/xstudio.desktop > /dev/null << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio ${XSTUDIO_VERSION}
Comment=Professional Media Playback and Review
Exec=/usr/local/bin/xstudio %U
Icon=${PREFIX}/share/icons/xstudio.png
Terminal=false
Categories=AudioVideo;Video;Player;
MimeType=video/*;image/*;
StartupNotify=true
EOF

sudo update-desktop-database 2>/dev/null || true

print_success "Desktop entry created"

###############################################################################
# Set Final Permissions
###############################################################################

print_section "Setting Final Permissions"

sudo chown -R root:root ${XSTUDIO_INSTALL_PATH}
sudo chmod -R 755 ${XSTUDIO_INSTALL_PATH}

print_success "Permissions set"

###############################################################################
# Final Summary
###############################################################################

print_section "Installation Complete!"

cat << SUMMARY

${GREEN}${BOLD}✓ xStudio Installation Complete!${NC}

${BOLD}Installation Details:${NC}
  Version:           ${XSTUDIO_VERSION}
  Location:          ${XSTUDIO_INSTALL_PATH}
  Launch Command:    xstudio

${BOLD}Features:${NC}
  ✓ Python scripting enabled
  ✓ OpenTimelineIO support
  ✓ System Qt6 integration
  ✓ All dependencies bundled
  ✓ RV coexistence ready
  ✓ SELinux configured

${BOLD}How to Run:${NC}
  Command line:      xstudio
  Applications:      Search for "xStudio"

${BOLD}Testing:${NC}
  1. Test xStudio:   xstudio
  2. Test RV:        rv (if installed)

${GREEN}Build completed successfully!${NC}

SUMMARY

print_info "Build directory: ${TMP_BUILD_DIR}"
print_warning "You can safely delete the build directory after testing:"
print_warning "  rm -rf ${TMP_BUILD_DIR}"

print_section "Next Steps"
print_info "1. Test xStudio launches: xstudio"
print_info "2. Test RV coexistence (if RV installed): rv"
print_info "3. If successful, clean build directory"
print_info "4. Deploy to other machines or create tar archive"

exit 0
