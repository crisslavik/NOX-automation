#!/bin/bash
# xStudio Complete Build and Deployment Script for AlmaLinux 9.6
# This script builds, deploys, and cleans up in one go

cat > ~/xstudio_full_build_and_deploy.sh << 'BUILD_SCRIPT_EOF'
#!/bin/bash

set -e  # Exit on any error

# Configuration
MAKE_JOBS=8
BUILD_DIR=${HOME}/tmp_build_xstudio
INSTALL_DIR=/opt/xstudio
USE_VENV=true  # Set to false to disable Python venv

# Version configuration
VER_XSTUDIO=main
VER_ACTOR=1.0.2
VER_AUTOCONF=2.72
VER_FDK_AAC=latest
VER_FFMPEG=5.1
VER_FMTLIB=8.0.1
VER_libGLEW=2.1.0
VER_NASM=2.15.05
VER_NLOHMANN=3.11.2
VER_OCIO2=2.2.0
VER_OPENEXR=RB-3.1
VER_OpenTimelineIO=cxx17
VER_PYTHON=3.9
VER_SPDLOG=1.9.2
VER_x264=stable
VER_x265=3.5
VER_YASM=1.3.0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "Do not run this script as root. Run as regular user with sudo access."
   exit 1
fi

log_info "=== xStudio Complete Build & Deploy Script ==="
log_info "Build directory: ${BUILD_DIR}"
log_info "Install directory: ${INSTALL_DIR}"
log_info "Python venv: ${USE_VENV}"
echo ""

# Ask for confirmation
read -p "This will build xStudio from scratch. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted by user"
    exit 0
fi

# Clean old build if exists
if [ -d "${BUILD_DIR}" ]; then
    log_warn "Removing existing build directory..."
    rm -rf ${BUILD_DIR}
fi

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# ===== SYSTEM PACKAGES =====
log_info "Step 1: Installing system packages..."

sudo dnf config-manager --set-enabled crb -y
sudo dnf install epel-release -y
sudo dnf update -y
sudo dnf groupinstall "Development Tools" -y

sudo dnf install wget git cmake autoconf automake libtool -y
sudo dnf install python3-devel pybind11-devel -y
sudo dnf install alsa-lib-devel pulseaudio-libs-devel -y
sudo dnf install freeglut-devel libjpeg-devel libuuid-devel -y
sudo dnf install libXmu-devel libXi-devel libGL-devel -y
sudo dnf install doxygen python3-sphinx -y
sudo dnf install opus-devel libvpx-devel openjpeg2-devel lame-devel -y
sudo dnf install qt6-qtbase-devel qt6-qtsvg-devel qt6-qttools-devel -y
sudo dnf install qt6-qtwebsockets-devel qt6-qtwebengine-devel -y
sudo dnf install yasm yasm-devel freetype-devel -y

# Python packages
if [ "$USE_VENV" = true ]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv ${BUILD_DIR}/xstudio_venv
    source ${BUILD_DIR}/xstudio_venv/bin/activate
fi

pip3 install --user sphinx_rtd_theme breathe

# ===== BUILD DEPENDENCIES =====
log_info "Step 2: Building libGLEW..."
cd ${BUILD_DIR}
wget https://sourceforge.net/projects/glew/files/glew/${VER_libGLEW}/glew-${VER_libGLEW}.tgz
tar -xf glew-${VER_libGLEW}.tgz
cd glew-${VER_libGLEW}/
make -j${MAKE_JOBS}
sudo make install

log_info "Step 3: Building NLOHMANN JSON..."
cd ${BUILD_DIR}
wget https://github.com/nlohmann/json/archive/refs/tags/v${VER_NLOHMANN}.tar.gz
tar -xf v${VER_NLOHMANN}.tar.gz
mkdir json-${VER_NLOHMANN}/build
cd json-${VER_NLOHMANN}/build
cmake .. -DJSON_BuildTests=Off
make -j${MAKE_JOBS}
sudo make install

log_info "Step 4: Building OpenEXR..."
cd ${BUILD_DIR}
git clone https://github.com/AcademySoftwareFoundation/openexr.git
cd openexr/
git checkout ${VER_OPENEXR}
mkdir build
cd build
cmake .. -DOPENEXR_INSTALL_TOOLS=Off -DBUILD_TESTING=Off
make -j${MAKE_JOBS}
sudo make install

log_info "Step 5: Building ActorFramework..."
cd ${BUILD_DIR}
git clone https://github.com/actor-framework/actor-framework
cd actor-framework
git checkout ${VER_ACTOR}
./configure
cd build
make -j${MAKE_JOBS}
sudo make install

log_info "Step 6: Building OpenColorIO..."
cd ${BUILD_DIR}
wget https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v${VER_OCIO2}.tar.gz
tar -xf v${VER_OCIO2}.tar.gz
cd OpenColorIO-${VER_OCIO2}/
mkdir build
cd build
cmake -DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_TESTS=OFF -DOCIO_BUILD_GPU_TESTS=OFF ../
make -j${MAKE_JOBS}
sudo make install

log_info "Step 7: Building SPDLOG..."
cd ${BUILD_DIR}
wget https://github.com/gabime/spdlog/archive/refs/tags/v${VER_SPDLOG}.tar.gz
tar -xf v${VER_SPDLOG}.tar.gz
cd spdlog-${VER_SPDLOG}
mkdir build
cd build
cmake .. -DSPDLOG_BUILD_SHARED=On
make -j${MAKE_JOBS}
sudo make install

log_info "Step 8: Building FMTLIB..."
cd ${BUILD_DIR}
wget https://github.com/fmtlib/fmt/archive/refs/tags/${VER_FMTLIB}.tar.gz
tar -xf ${VER_FMTLIB}.tar.gz
cd fmt-${VER_FMTLIB}/
mkdir build
cd build
cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=1 -DFMT_DOC=Off -DFMT_TEST=Off
make -j${MAKE_JOBS}
sudo make install

log_info "Step 9: Building OpenTimelineIO..."
cd ${BUILD_DIR}
git clone https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git
cd OpenTimelineIO
git checkout ${VER_OpenTimelineIO}
mkdir build
cd build
cmake -DOTIO_PYTHON_INSTALL=ON -DOTIO_DEPENDENCIES_INSTALL=OFF -DOTIO_FIND_IMATH=ON ..
make -j${MAKE_JOBS}
sudo make install

# ===== FFMPEG AND CODECS =====
log_info "Step 10: Building NASM..."
cd ${BUILD_DIR}
wget https://www.nasm.us/pub/nasm/releasebuilds/${VER_NASM}/nasm-${VER_NASM}.tar.bz2
tar -xf nasm-${VER_NASM}.tar.bz2
cd nasm-${VER_NASM}
./autogen.sh
./configure
make -j${MAKE_JOBS}
sudo make install

log_info "Step 11: Building YASM..."
cd ${BUILD_DIR}
wget https://www.tortall.net/projects/yasm/releases/yasm-${VER_YASM}.tar.gz
tar -xf yasm-${VER_YASM}.tar.gz
cd yasm-${VER_YASM}
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make -j${MAKE_JOBS}
sudo make install

log_info "Step 12: Building x264..."
cd ${BUILD_DIR}
git clone --branch ${VER_x264} --depth 1 https://code.videolan.org/videolan/x264.git
cd x264/
./configure --enable-shared
make -j${MAKE_JOBS}
sudo make install

log_info "Step 13: Building x265..."
cd ${BUILD_DIR}
wget https://bitbucket.org/multicoreware/x265_git/downloads/x265_${VER_x265}.tar.gz
tar -xf x265_${VER_x265}.tar.gz
cd x265_${VER_x265}/build/linux/
cmake -G "Unix Makefiles" ../../source
make -j${MAKE_JOBS}
sudo make install

log_info "Step 14: Building FDK-AAC..."
cd ${BUILD_DIR}
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure
make -j${MAKE_JOBS}
sudo make install

log_info "Step 15: Building FFmpeg..."
cd ${BUILD_DIR}
wget https://ffmpeg.org/releases/ffmpeg-${VER_FFMPEG}.tar.bz2
tar -xf ffmpeg-${VER_FFMPEG}.tar.bz2
cd ffmpeg-${VER_FFMPEG}/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
./configure --extra-libs=-lpthread --extra-libs=-lm --enable-gpl \
    --enable-libfdk_aac --enable-libfreetype --enable-libmp3lame \
    --enable-libopus --enable-libvpx --enable-libx264 --enable-libx265 \
    --enable-shared --enable-nonfree --disable-vulkan
make -j${MAKE_JOBS}
sudo make install

# Update library cache
sudo tee /etc/ld.so.conf.d/usr-local-lib.conf > /dev/null << 'EOF'
/usr/local/lib
/usr/local/lib64
EOF
sudo ldconfig

# ===== BUILD XSTUDIO =====
log_info "Step 16: Building xStudio..."
cd ${BUILD_DIR}
git clone https://github.com/AcademySoftwareFoundation/xstudio.git
cd xstudio
git checkout ${VER_XSTUDIO}

# Remove RV paths from environment for build
export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export PATH=/usr/local/bin:$PATH

mkdir build
cd build
cmake .. -DBUILD_DOCS=Off
make -j${MAKE_JOBS}

log_info "Step 17: xStudio build complete!"

# ===== DEPLOYMENT =====
log_info "Step 18: Deploying to ${INSTALL_DIR}..."

sudo rm -rf ${INSTALL_DIR}
sudo mkdir -p ${INSTALL_DIR}
sudo cp -a ${BUILD_DIR}/xstudio/build/* ${INSTALL_DIR}/
sudo cp -r ${BUILD_DIR}/xstudio/docs ${INSTALL_DIR}/

# Set permissions
sudo chown -R root:root ${INSTALL_DIR}
sudo find ${INSTALL_DIR} -type d -exec chmod 755 {} \;
sudo find ${INSTALL_DIR} -type f -exec chmod 644 {} \;
sudo find ${INSTALL_DIR}/bin -type f -exec chmod 755 {} \;
sudo chmod 755 ${INSTALL_DIR}/bin/lib/*.so*
sudo chmod 755 ${INSTALL_DIR}/bin/plugin/*.so*

# Create launcher
log_info "Step 19: Creating launcher script..."
sudo tee ${INSTALL_DIR}/xstudio.sh > /dev/null << 'LAUNCHER_EOF'
#!/bin/bash
# xStudio Launcher

# Remove any RV/Autodesk paths from environment
export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')

# Set xStudio environment
export QV4_FORCE_INTERPRETER=1
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=/opt/xstudio/bin/python/lib/python3.9/site-packages:$HOME/.local/lib/python3.9/site-packages:$PYTHONPATH
export PATH=/usr/local/bin:$PATH

# Launch xStudio
cd /opt/xstudio
exec ./bin/xstudio.bin "$@"
LAUNCHER_EOF

sudo chmod 755 ${INSTALL_DIR}/xstudio.sh

# Install desktop icon
log_info "Step 20: Installing desktop launcher..."
sudo cp ${INSTALL_DIR}/docs/user_docs/images/xstudio-logo.png /usr/share/pixmaps/xstudio.png

sudo tee /usr/share/applications/xstudio.desktop > /dev/null << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio
Comment=Professional media playback and review application for VFX
Exec=/opt/xstudio/xstudio.sh
Icon=/usr/share/pixmaps/xstudio.png
Terminal=false
Categories=AudioVideo;Video;Player;Graphics;
Keywords=video;player;review;vfx;playback;
StartupNotify=true
DESKTOP_EOF

sudo update-desktop-database /usr/share/applications/
sudo gtk-update-icon-cache /usr/share/pixmaps/ -f 2>/dev/null || true

# ===== CLEANUP =====
log_info "Step 21: Cleaning up build directory..."
read -p "Remove build directory ${BUILD_DIR}? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ${HOME}
    rm -rf ${BUILD_DIR}
    log_info "Build directory removed"
else
    log_warn "Build directory kept at: ${BUILD_DIR}"
fi

# Deactivate venv if used
if [ "$USE_VENV" = true ]; then
    deactivate 2>/dev/null || true
fi

# ===== DONE =====
log_info "==================================="
log_info "xStudio Installation Complete!"
log_info "==================================="
echo ""
log_info "Installed to: ${INSTALL_DIR}"
log_info "Launch: ${INSTALL_DIR}/xstudio.sh"
log_info "Desktop launcher available in Applications menu"
echo ""
log_warn "NOTE: Logout/login for desktop icon to appear properly"
echo ""
BUILD_SCRIPT_EOF

chmod +x ~/xstudio_full_build_and_deploy.sh

echo "Complete build script created: ~/xstudio_full_build_and_deploy.sh"
echo ""
echo "To run:"
echo "  ~/xstudio_full_build_and_deploy.sh"
