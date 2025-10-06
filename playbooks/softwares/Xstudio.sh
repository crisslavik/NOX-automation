cat > ~/xstudio_complete_installer.sh << 'COMPLETE_SCRIPT'
#!/bin/bash
# xStudio Complete Installation Script for AlmaLinux 9.6
# Clones, builds, installs, and configures xStudio in one go

set -e  # Exit on any error

# Configuration
MAKE_JOBS=$(nproc)
BUILD_DIR=${HOME}/tmp_build_xstudio
INSTALL_DIR=/opt/xstudio

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if root
if [[ $EUID -eq 0 ]]; then
   log_error "Do not run as root. Run as regular user with sudo access."
   exit 1
fi

log_info "=== xStudio Complete Installation Script ==="
log_info "This will:"
log_info "  1. Install all dependencies"
log_info "  2. Clone and build xStudio"
log_info "  3. Install to /opt/xstudio"
log_info "  4. Create desktop launcher"
log_info "  5. Clean up build directory"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Clean old build
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

pip3 install --user sphinx_rtd_theme breathe

# ===== BUILD DEPENDENCIES =====
cd ${BUILD_DIR}

log_info "Building libGLEW..."
wget -q https://sourceforge.net/projects/glew/files/glew/2.1.0/glew-2.1.0.tgz
tar -xf glew-2.1.0.tgz
cd glew-2.1.0/
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building NLOHMANN JSON..."
cd ${BUILD_DIR}
wget -q https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.tar.gz
tar -xf v3.11.2.tar.gz
mkdir json-3.11.2/build
cd json-3.11.2/build
cmake .. -DJSON_BuildTests=Off > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building OpenEXR..."
cd ${BUILD_DIR}
git clone -q https://github.com/AcademySoftwareFoundation/openexr.git
cd openexr/
git checkout -q RB-3.1
mkdir build && cd build
cmake .. -DOPENEXR_INSTALL_TOOLS=Off -DBUILD_TESTING=Off > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building ActorFramework..."
cd ${BUILD_DIR}
git clone -q https://github.com/actor-framework/actor-framework
cd actor-framework
git checkout -q 1.0.2
./configure > /dev/null 2>&1
cd build
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building OpenColorIO..."
cd ${BUILD_DIR}
wget -q https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v2.2.0.tar.gz
tar -xf v2.2.0.tar.gz
cd OpenColorIO-2.2.0/
mkdir build && cd build
cmake -DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_TESTS=OFF -DOCIO_BUILD_GPU_TESTS=OFF ../ > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building SPDLOG..."
cd ${BUILD_DIR}
wget -q https://github.com/gabime/spdlog/archive/refs/tags/v1.9.2.tar.gz
tar -xf v1.9.2.tar.gz
cd spdlog-1.9.2
mkdir build && cd build
cmake .. -DSPDLOG_BUILD_SHARED=On > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building FMTLIB..."
cd ${BUILD_DIR}
wget -q https://github.com/fmtlib/fmt/archive/refs/tags/8.0.1.tar.gz
tar -xf 8.0.1.tar.gz
cd fmt-8.0.1/
mkdir build && cd build
cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=1 -DFMT_DOC=Off -DFMT_TEST=Off > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building NASM..."
cd ${BUILD_DIR}
wget -q https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
tar -xf nasm-2.15.05.tar.bz2
cd nasm-2.15.05
./autogen.sh > /dev/null 2>&1
./configure > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building x264..."
cd ${BUILD_DIR}
git clone -q --branch stable --depth 1 https://code.videolan.org/videolan/x264.git
cd x264/
./configure --enable-shared > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building x265..."
cd ${BUILD_DIR}
wget -q https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.5.tar.gz
tar -xf x265_3.5.tar.gz
cd x265_3.5/build/linux/
cmake -G "Unix Makefiles" ../../source > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building FDK-AAC..."
cd ${BUILD_DIR}
git clone -q --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv > /dev/null 2>&1
./configure > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

log_info "Building FFmpeg..."
cd ${BUILD_DIR}
wget -q https://ffmpeg.org/releases/ffmpeg-5.1.tar.bz2
tar -xf ffmpeg-5.1.tar.bz2
cd ffmpeg-5.1/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
./configure --extra-libs=-lpthread --extra-libs=-lm --enable-gpl \
    --enable-libfdk_aac --enable-libfreetype --enable-libmp3lame \
    --enable-libopus --enable-libvpx --enable-libx264 --enable-libx265 \
    --enable-shared --enable-nonfree --disable-vulkan > /dev/null 2>&1
make -j${MAKE_JOBS} > /dev/null 2>&1
sudo make install > /dev/null 2>&1

# Update library cache
sudo tee /etc/ld.so.conf.d/usr-local-lib.conf > /dev/null << 'EOF'
/usr/local/lib
/usr/local/lib64
EOF
sudo ldconfig

# ===== BUILD XSTUDIO =====
log_info "Cloning and building xStudio..."
cd ${BUILD_DIR}
git clone -q https://github.com/AcademySoftwareFoundation/xstudio.git
cd xstudio
git checkout -q main

# Remove RV paths
export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

mkdir build && cd build
cmake .. -DBUILD_DOCS=Off > /dev/null 2>&1
log_info "Compiling xStudio (this takes 10-15 minutes)..."
make -j${MAKE_JOBS}

log_info "xStudio build complete!"

# ===== DEPLOYMENT =====
log_info "Installing to ${INSTALL_DIR}..."
sudo rm -rf ${INSTALL_DIR}
sudo mkdir -p ${INSTALL_DIR}
sudo cp -a ${BUILD_DIR}/xstudio/build/* ${INSTALL_DIR}/
sudo cp -r ${BUILD_DIR}/xstudio/docs ${INSTALL_DIR}/

# Set permissions
sudo chown -R root:root ${INSTALL_DIR}
sudo find ${INSTALL_DIR} -type d -exec chmod 755 {} \;
sudo find ${INSTALL_DIR} -type f -exec chmod 644 {} \;
sudo find ${INSTALL_DIR}/bin -type f -exec chmod 755 {} \;
sudo chmod 755 ${INSTALL_DIR}/bin/lib/*.so* 2>/dev/null || true
sudo chmod 755 ${INSTALL_DIR}/bin/plugin/*.so* 2>/dev/null || true

# Create launcher
log_info "Creating launcher script..."
sudo tee ${INSTALL_DIR}/xstudio.sh > /dev/null << 'LAUNCHER'
#!/bin/bash
export PATH=$(echo $PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | tr '\n' ':')
export QV4_FORCE_INTERPRETER=1
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=/opt/xstudio/bin/python/lib/python3.9/site-packages:$HOME/.local/lib/python3.9/site-packages:$PYTHONPATH
export PATH=/usr/local/bin:$PATH
cd /opt/xstudio
exec ./bin/xstudio.bin "$@"
LAUNCHER
sudo chmod 755 ${INSTALL_DIR}/xstudio.sh

# Desktop integration
log_info "Creating desktop launcher..."
sudo cp ${INSTALL_DIR}/docs/user_docs/images/xstudio-logo.png /usr/share/pixmaps/xstudio.png 2>/dev/null || true

sudo tee /usr/share/applications/xstudio.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio
Comment=Professional media playback and review application
Exec=/opt/xstudio/xstudio.sh
Icon=/usr/share/pixmaps/xstudio.png
Terminal=false
Categories=AudioVideo;Video;Player;Graphics;
Keywords=video;player;review;vfx;playback;
StartupNotify=true
DESKTOP

sudo update-desktop-database /usr/share/applications/
sudo gtk-update-icon-cache /usr/share/pixmaps/ -f 2>/dev/null || true

# ===== CLEANUP =====
log_info "Cleaning up build directory..."
cd ${HOME}
rm -rf ${BUILD_DIR}

log_info "==================================="
log_info "Installation Complete!"
log_info "==================================="
echo ""
log_info "Launch: /opt/xstudio/xstudio.sh"
log_info "Desktop launcher available in Applications menu"
echo ""
log_warn "NOTE: Logout/login for desktop icon to appear properly"
COMPLETE_SCRIPT

chmod +x ~/xstudio_complete_installer.sh
echo "Complete installer created: ~/xstudio_complete_installer.sh"
echo ""
echo "Run with: ~/xstudio_complete_installer.sh"
