cat > ~/xstudio_complete_installer_fixed.sh << 'COMPLETE_SCRIPT'
#!/bin/bash
# xStudio Complete Installation Script for AlmaLinux 9.6 - FIXED
# Handles CMake 3.28+, Qt6, and OpenTimelineIO

set -e
MAKE_JOBS=$(nproc)
BUILD_DIR=${HOME}/tmp_build_xstudio
INSTALL_DIR=/opt/xstudio

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
   log_error "Do not run as root. Run as regular user with sudo access."
   exit 1
fi

log_info "=== xStudio Complete Installation ==="
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi

if [ -d "${BUILD_DIR}" ]; then
    log_warn "Removing existing build directory..."
    rm -rf ${BUILD_DIR}
fi
mkdir -p ${BUILD_DIR}

# ===== SYSTEM PACKAGES =====
log_info "Installing system packages..."
sudo dnf config-manager --set-enabled crb -y
sudo dnf install epel-release -y
sudo dnf update -y
sudo dnf groupinstall "Development Tools" -y
sudo dnf install wget git autoconf automake libtool -y
sudo dnf install python3-devel -y
sudo dnf install alsa-lib-devel pulseaudio-libs-devel -y
sudo dnf install freeglut-devel libjpeg-devel libuuid-devel -y
sudo dnf install libXmu-devel libXi-devel libGL-devel -y
sudo dnf install doxygen python3-sphinx -y
sudo dnf install opus-devel libvpx-devel openjpeg2-devel lame-devel -y
sudo dnf install qt6-qtbase-devel qt6-qtsvg-devel qt6-qttools-devel -y
sudo dnf install qt6-qtwebsockets-devel qt6-qtwebengine-devel -y
sudo dnf install yasm yasm-devel freetype-devel -y

pip3 install --user sphinx_rtd_theme breathe pybind11 cmake

# Add pip binaries to PATH
export PATH=$HOME/.local/bin:$PATH
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

# Verify CMake version
CMAKE_VER=$(cmake --version | head -n1 | awk '{print $3}')
log_info "Using CMake version: $CMAKE_VER"

cd ${BUILD_DIR}

# ===== BUILD DEPENDENCIES (same as before) =====
log_info "Building libGLEW..."
wget -q https://sourceforge.net/projects/glew/files/glew/2.1.0/glew-2.1.0.tgz
tar -xf glew-2.1.0.tgz && cd glew-2.1.0/
make -j${MAKE_JOBS} && sudo make install

log_info "Building NLOHMANN JSON..."
cd ${BUILD_DIR}
wget -q https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.tar.gz
tar -xf v3.11.2.tar.gz && cd json-3.11.2
mkdir build && cd build
cmake .. -DJSON_BuildTests=Off && make -j${MAKE_JOBS} && sudo make install

log_info "Building OpenEXR..."
cd ${BUILD_DIR}
git clone -q https://github.com/AcademySoftwareFoundation/openexr.git
cd openexr && git checkout -q RB-3.1
mkdir build && cd build
cmake .. -DOPENEXR_INSTALL_TOOLS=Off -DBUILD_TESTING=Off
make -j${MAKE_JOBS} && sudo make install

log_info "Building ActorFramework..."
cd ${BUILD_DIR}
git clone -q https://github.com/actor-framework/actor-framework
cd actor-framework && git checkout -q 1.0.2
./configure && cd build
make -j${MAKE_JOBS} && sudo make install

log_info "Building OpenColorIO..."
cd ${BUILD_DIR}
wget -q https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v2.2.0.tar.gz
tar -xf v2.2.0.tar.gz && cd OpenColorIO-2.2.0
mkdir build && cd build
cmake -DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_TESTS=OFF -DOCIO_BUILD_GPU_TESTS=OFF ../
make -j${MAKE_JOBS} && sudo make install

log_info "Building SPDLOG..."
cd ${BUILD_DIR}
wget -q https://github.com/gabime/spdlog/archive/refs/tags/v1.9.2.tar.gz
tar -xf v1.9.2.tar.gz && cd spdlog-1.9.2
mkdir build && cd build
cmake .. -DSPDLOG_BUILD_SHARED=On
make -j${MAKE_JOBS} && sudo make install

log_info "Building FMTLIB..."
cd ${BUILD_DIR}
wget -q https://github.com/fmtlib/fmt/archive/refs/tags/8.0.1.tar.gz
tar -xf 8.0.1.tar.gz && cd fmt-8.0.1
mkdir build && cd build
cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=1 -DFMT_DOC=Off -DFMT_TEST=Off
make -j${MAKE_JOBS} && sudo make install

log_info "Building NASM..."
cd ${BUILD_DIR}
wget -q https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
tar -xf nasm-2.15.05.tar.bz2 && cd nasm-2.15.05
./autogen.sh && ./configure
make -j${MAKE_JOBS} && sudo make install

log_info "Building x264..."
cd ${BUILD_DIR}
git clone -q --branch stable --depth 1 https://code.videolan.org/videolan/x264.git
cd x264 && ./configure --enable-shared
make -j${MAKE_JOBS} && sudo make install

log_info "Building x265..."
cd ${BUILD_DIR}
wget -q https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.5.tar.gz
tar -xf x265_3.5.tar.gz && cd x265_3.5/build/linux/
cmake -G "Unix Makefiles" ../../source
make -j${MAKE_JOBS} && sudo make install

log_info "Building FDK-AAC..."
cd ${BUILD_DIR}
git clone -q --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac && autoreconf -fiv
./configure && make -j${MAKE_JOBS} && sudo make install

log_info "Building FFmpeg..."
cd ${BUILD_DIR}
wget -q https://ffmpeg.org/releases/ffmpeg-5.1.tar.bz2
tar -xf ffmpeg-5.1.tar.bz2 && cd ffmpeg-5.1/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
./configure --extra-libs=-lpthread --extra-libs=-lm --enable-gpl \
    --enable-libfdk_aac --enable-libfreetype --enable-libmp3lame \
    --enable-libopus --enable-libvpx --enable-libx264 --enable-libx265 \
    --enable-shared --enable-nonfree --disable-vulkan
make -j${MAKE_JOBS} && sudo make install

# NEW: Build OpenTimelineIO
log_info "Building OpenTimelineIO..."
cd ${BUILD_DIR}
git clone -q https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git
cd OpenTimelineIO && git checkout -q cxx17
mkdir build && cd build
cmake -DOTIO_PYTHON_INSTALL=ON -DOTIO_DEPENDENCIES_INSTALL=OFF -DOTIO_FIND_IMATH=ON ..
make -j${MAKE_JOBS} && sudo make install

# Update library cache
sudo tee /etc/ld.so.conf.d/usr-local-lib.conf > /dev/null << 'EOF'
/usr/local/lib
/usr/local/lib64
EOF
sudo ldconfig

# ===== BUILD XSTUDIO =====
log_info "Cloning xStudio..."
cd ${BUILD_DIR}
git clone -q https://github.com/AcademySoftwareFoundation/xstudio.git
cd xstudio && git checkout -q main

export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export Qt6_DIR=/usr/lib64/cmake/Qt6
export pybind11_DIR=$(python3 -c "import pybind11; print(pybind11.get_cmake_dir())")

mkdir build && cd build

log_info "Configuring xStudio..."
cmake .. -DBUILD_DOCS=Off \
  -DQt6_DIR=$Qt6_DIR \
  -Dpybind11_DIR=$pybind11_DIR

log_info "Building xStudio (15-20 minutes)..."
make -j${MAKE_JOBS}

# ===== DEPLOYMENT =====
log_info "Installing to ${INSTALL_DIR}..."
sudo rm -rf ${INSTALL_DIR}
sudo mkdir -p ${INSTALL_DIR}
sudo cp -a ${BUILD_DIR}/xstudio/build/* ${INSTALL_DIR}/
sudo cp -r ${BUILD_DIR}/xstudio/docs ${INSTALL_DIR}/

sudo chown -R root:root ${INSTALL_DIR}
sudo find ${INSTALL_DIR} -type d -exec chmod 755 {} \;
sudo find ${INSTALL_DIR} -type f -exec chmod 644 {} \;
sudo find ${INSTALL_DIR}/bin -type f -exec chmod 755 {} \;
sudo chmod 755 ${INSTALL_DIR}/bin/lib/*.so* 2>/dev/null || true
sudo chmod 755 ${INSTALL_DIR}/bin/plugin/*.so* 2>/dev/null || true

sudo tee ${INSTALL_DIR}/xstudio.sh > /dev/null << 'LAUNCHER'
#!/bin/bash
export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export QV4_FORCE_INTERPRETER=1
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=/opt/xstudio/bin/python/lib/python3.9/site-packages:${HOME}/.local/lib/python3.9/site-packages:$PYTHONPATH
export PATH=/usr/local/bin:$PATH
cd /opt/xstudio
exec ./bin/xstudio.bin "$@"
LAUNCHER
sudo chmod 755 ${INSTALL_DIR}/xstudio.sh

log_info "Creating desktop launcher..."
sudo cp ${INSTALL_DIR}/docs/user_docs/images/xstudio-logo.png /usr/share/pixmaps/xstudio.png 2>/dev/null || true

sudo tee /usr/share/applications/xstudio.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio
Comment=Professional media playback and review
Exec=/opt/xstudio/xstudio.sh
Icon=/usr/share/pixmaps/xstudio.png
Terminal=false
Categories=AudioVideo;Video;Player;Graphics;
Keywords=video;player;review;vfx;
StartupNotify=true
DESKTOP

sudo update-desktop-database /usr/share/applications/
sudo gtk-update-icon-cache /usr/share/pixmaps/ -f 2>/dev/null || true

log_info "Cleaning up..."
cd ${HOME}
rm -rf ${BUILD_DIR}

log_info "==================================="
log_info "Installation Complete!"
log_info "==================================="
echo ""
log_info "Launch: /opt/xstudio/xstudio.sh"
log_info "Works for all AD users automatically"
COMPLETE_SCRIPT

chmod +x ~/xstudio_complete_installer_fixed.sh
echo "Fixed installer created: ~/xstudio_complete_installer_fixed.sh"
