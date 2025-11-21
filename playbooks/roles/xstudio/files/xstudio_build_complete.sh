
#!/bin/bash

# Log stdout and stderr to file
TMP_XSTUDIO_BUILD_TIME=$(date +%Y%m%d%H%M%S)
TMP_XSTUDIO_BUILD_LOG=xstudiobuild-${TMP_XSTUDIO_BUILD_TIME}.log
exec >  >(tee -ia ${TMP_XSTUDIO_BUILD_LOG})
exec 2> >(tee -ia ${TMP_XSTUDIO_BUILD_LOG} >&2)

# Color definitions
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function for colored output that also logs
print_section() {
	echo -e "${PURPLE}${BOLD}===============================================${NC}"
	echo -e "${PURPLE}${BOLD}=== $1 ===${NC}"
	echo -e "${PURPLE}${BOLD}===============================================${NC}"
}

print_subsection() {
	echo -e "${CYAN}${BOLD}--- $1 ---${NC}"
}

print_success() {
	echo -e "${GREEN}${BOLD}✓ $1${NC}"
}

print_info() {
	echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
}

# Build configuration
JOBS=8
TMP_XSTUDIO_BUILD_DIR=${HOME}/tmp_build_xstudio
CMAKE_VERSION=3.31.0  # Updated to match requirement

# Qt configuration
QT_VERSION="6.5.3"
QT_BASE_PATH="/opt/Qt"  # Default Qt installation path
AUTO_COMPILE=true  # Set to false to skip compilation even if Qt is found

# Allow Qt path override via command line argument
if [ ! -z "$1" ]; then
	if [ "$1" == "--skip-compile" ]; then
		AUTO_COMPILE=false
	else
		QT_BASE_PATH="$1"
	fi
fi

# Component versions (updated from Rocky Linux 9.1 guide)
VER_ACTOR=1.1.0
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
VER_XSTUDIO=main

# Create build directory
mkdir -p ${TMP_XSTUDIO_BUILD_DIR}
cd ${TMP_XSTUDIO_BUILD_DIR}

print_section "xStudio Complete Build for AlmaLinux 9.6"
print_info "Build directory: ${TMP_XSTUDIO_BUILD_DIR}"
print_info "Log file: ${TMP_XSTUDIO_BUILD_LOG}"
print_info "CMake version to install: ${CMAKE_VERSION}"
print_info "Jobs for parallel compilation: ${JOBS}"
print_info "Auto-compile if Qt found: ${AUTO_COMPILE}"

# Check available disk space
AVAILABLE_SPACE=$(df -BG ${HOME} | awk 'NR==2 {print $4}' | sed 's/G//')
print_info "Available disk space: ${AVAILABLE_SPACE}GB"
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
	print_error "Low disk space! At least 20GB recommended for building xStudio"
	print_info "Current available: ${AVAILABLE_SPACE}GB"
	read -p "Continue anyway? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		print_error "Build cancelled due to low disk space"
		exit 1
	fi
fi

# Increase file descriptor limit
print_info "Increasing file descriptor limit..."
ulimit -n 4096
print_success "File descriptor limit set to: $(ulimit -n)"

### Check and Install CMake
print_section "CMake Version Management"

# Check current cmake version
CURRENT_CMAKE_VERSION=$(cmake --version 2>/dev/null | grep version | awk '{print $3}')
print_info "Current CMake version: ${CURRENT_CMAKE_VERSION:-Not installed}"

# Function to compare version numbers
version_ge() {
	[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Install CMake if needed (xStudio requires 3.28+)
if ! command -v cmake &> /dev/null || ! version_ge "${CURRENT_CMAKE_VERSION}" "3.28"; then
	print_warning "Installing CMake ${CMAKE_VERSION} (required: 3.28+)"
    
	cd ${TMP_XSTUDIO_BUILD_DIR}
	wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
	tar -xzf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz
    
	# Install to /usr/local
	sudo rm -rf /usr/local/cmake
	sudo mv cmake-${CMAKE_VERSION}-linux-x86_64 /usr/local/cmake
    
	# Create symlinks
	sudo ln -sf /usr/local/cmake/bin/cmake /usr/local/bin/cmake
	sudo ln -sf /usr/local/cmake/bin/ctest /usr/local/bin/ctest
	sudo ln -sf /usr/local/cmake/bin/cpack /usr/local/bin/cpack
	sudo ln -sf /usr/local/cmake/bin/ccmake /usr/local/bin/ccmake
    
	# Update PATH
	export PATH=/usr/local/cmake/bin:$PATH
    
	# Add to bashrc for persistence
	if ! grep -q "/usr/local/cmake/bin" ~/.bashrc; then
		echo 'export PATH=/usr/local/cmake/bin:$PATH' >> ~/.bashrc
	fi
    
	print_success "CMake ${CMAKE_VERSION} installed successfully"
	cmake --version
else
	print_success "CMake version is sufficient (${CURRENT_CMAKE_VERSION})"
fi

### Distro repository setup and package installation
print_section "Configuring AlmaLinux repositories"

# Enable CRB (CodeReady Builder) repository
print_info "Enabling CRB repository..."
sudo dnf config-manager --set-enabled crb

# Install EPEL repository (required for some packages)
print_info "Installing EPEL repository..."
sudo dnf install -y epel-release

# Update system
print_info "Updating system packages..."
sudo dnf update -y

print_section "Installing System Packages"

# Development Tools
print_subsection "Installing Development Tools"
sudo dnf groupinstall "Development Tools" -y

# Core build tools and libraries (matching Rocky Linux guide)
print_subsection "Installing Core Build Tools"
sudo dnf install -y \
	git \
	gcc \
	gcc-c++ \
	make \
	automake \
	autoconf \
	libtool \
	pkg-config \
	python3-devel \
	pybind11-devel \
	boost-devel

# Audio libraries
print_subsection "Installing Audio Libraries"
sudo dnf install -y \
	alsa-lib-devel \
	pulseaudio-libs-devel

# Graphics and GUI libraries
print_subsection "Installing Graphics Libraries"
sudo dnf install -y \
	freeglut-devel \
	mesa-libGL-devel \
	mesa-libGLU-devel \
	libXi-devel \
	libXmu-devel \
	libjpeg-devel \
	libuuid-devel

# Documentation tools
print_subsection "Installing Documentation Tools"
sudo dnf install -y \
	doxygen \
	python3-sphinx

# Codec libraries
print_subsection "Installing Codec Libraries"
sudo dnf install -y \
	opus-devel \
	libvpx-devel \
	openjpeg2-devel \
	lame-devel \
	freetype-devel

# Additional dependencies from Rocky Linux guide
print_subsection "Installing Additional Dependencies"
sudo dnf install -y \
	libxkbcommon-x11-devel \
	xcb-util-devel \
	xcb-util-image-devel \
	xcb-util-keysyms-devel \
	xcb-util-renderutil-devel \
	xcb-util-wm-devel

# Python documentation tools
print_subsection "Installing Python Documentation Tools"
pip3 install --user sphinx_rtd_theme breathe

print_success "System packages installed successfully"

### Qt6 Installation
print_section "Installing Qt6 Development Environment"

print_info "Note: xStudio requires Qt 6.5.3 (or compatible version)"
print_info "This script will install system Qt6 packages for dependencies,"
print_info "but xStudio compilation may require Qt 6.5.3 from qt.io"

# Check for conflicting Qt installations (like Autodesk RV)
print_subsection "Checking for Qt Conflicts"
if [[ -d "/opt/Autodesk/RV-2025.0.0" ]]; then
	print_warning "Autodesk RV detected - may have conflicting Qt6 libraries"
	print_info "Will configure environment to prioritize system Qt6"
fi

print_subsection "Installing Qt6 Dependencies"
sudo dnf install -y \
	ninja-build \
	wayland-devel \
	libinput-devel

print_subsection "Installing System Qt6 Packages"
sudo dnf install -y \
	qt6-qtbase-devel \
	qt6-qtbase-gui \
	qt6-qtdeclarative-devel \
	qt6-qttools-devel \
	qt6-qtsvg-devel \
	qt6-qtwayland-devel \
	qt6-qt5compat-devel \
	qt6-qtmultimedia-devel \
	qt6-qtnetworkauth-devel \
	qt6-qtwebsockets-devel

# Configure Qt6 environment (prioritize system Qt6 over other installations)
print_subsection "Configuring Qt6 Environment"

# Remove any RV or other Qt paths from current session
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | tr '\n' ':' | sed 's/:$//')

# Set system Qt6 paths FIRST
export PATH="/usr/lib64/qt6/bin:$PATH"
export LD_LIBRARY_PATH="/usr/lib64/qt6/lib:/usr/lib64:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="/usr/lib64/qt6/plugins"
export QML2_IMPORT_PATH="/usr/lib64/qt6/qml"

# Verify and configure Qt6
if command -v qmake6 &> /dev/null; then
	# Try to run qmake6 with clean environment
	QT6_VERSION=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_VERSION 2>/dev/null)
	if [ $? -eq 0 ]; then
		QT6_INSTALL_PREFIX=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_INSTALL_PREFIX)
		print_success "System Qt6 installed: ${QT6_VERSION}"
		print_info "Qt6 location: ${QT6_INSTALL_PREFIX}"
		print_info "qmake6 path: $(which qmake6)"
        
		# Create a wrapper script for qmake6 to avoid library conflicts
		QMAKE6_WRAPPER="${HOME}/.local/bin/qmake6-clean"
		mkdir -p "${HOME}/.local/bin"
		cat > "${QMAKE6_WRAPPER}" << 'EOF'
#!/bin/bash
# qmake6 wrapper to avoid Qt library conflicts
export LD_LIBRARY_PATH="/usr/lib64/qt6/lib:/usr/lib64:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/usr/lib64/qt6/plugins"
exec /usr/bin/qmake6 "$@"
EOF
		chmod +x "${QMAKE6_WRAPPER}"
		print_success "Created qmake6 wrapper at: ${QMAKE6_WRAPPER}"
	else
		print_error "qmake6 found but not working properly"
		print_info "This may be due to library conflicts with other Qt installations"
	fi
else
	print_warning "qmake6 not found in PATH"
fi

# Add persistent environment configuration to bashrc
print_subsection "Adding Qt6 to shell environment"
QT_ENV_MARKER="# xStudio Qt6 Environment"
if ! grep -q "${QT_ENV_MARKER}" ~/.bashrc; then
	cat >> ~/.bashrc << 'EOF'

# xStudio Qt6 Environment
# Prioritize system Qt6 over other Qt installations (like Autodesk RV)
export PATH="/usr/lib64/qt6/bin:$PATH"
# Note: LD_LIBRARY_PATH for Qt6 is set in build scripts to avoid conflicts
export QT_PLUGIN_PATH="/usr/lib64/qt6/plugins"
export QML2_IMPORT_PATH="/usr/lib64/qt6/qml"
EOF
	print_success "Qt6 environment added to ~/.bashrc"
else
	print_info "Qt6 environment already configured in ~/.bashrc"
fi

# Check if system Qt6 version is compatible with xStudio
print_subsection "Checking Qt Compatibility"
if [[ "$QT6_VERSION" == 6.* ]]; then
	print_info "System Qt6 version: ${QT6_VERSION}"
	if [[ "$QT6_VERSION" == 6.5.* ]] || [[ "$QT6_VERSION" == 6.6.* ]] || [[ "$QT6_VERSION" == 6.7.* ]]; then
		print_success "System Qt6 version is compatible with xStudio!"
		print_info "You may be able to compile xStudio with system Qt6"
		# Store system Qt path for later use
		SYSTEM_QT_PATH=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_INSTALL_PREFIX)
	else
		print_warning "System Qt6 (${QT6_VERSION}) may not be fully compatible"
		print_info "xStudio officially supports Qt 6.5.3"
		print_info "You can download Qt 6.5.3 from: https://www.qt.io/download-qt-installer"
	fi
fi

### Set library paths
print_section "Setting Library Paths"

# Clean LD_LIBRARY_PATH from potential conflicts (RV, etc.)
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | tr '\n' ':' | sed 's/:$//')

# Set Qt6 libraries first, then local libraries
export LD_LIBRARY_PATH="/usr/lib64/qt6/lib:/usr/local/lib:/usr/local/lib64:/usr/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH

print_info "Qt6 libraries: /usr/lib64/qt6/lib (priority)"
print_info "Local libraries: /usr/local/lib:/usr/local/lib64"

# Add to ldconfig
echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/local.conf
echo '/usr/local/lib64' | sudo tee -a /etc/ld.so.conf.d/local.conf
sudo ldconfig

print_success "Library paths configured"

### Local library builds
print_section "Building libGLEW ${VER_libGLEW}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://sourceforge.net/projects/glew/files/glew/${VER_libGLEW}/glew-${VER_libGLEW}.tgz
tar -xf glew-${VER_libGLEW}.tgz
cd glew-${VER_libGLEW}/
make -j${JOBS} || { print_error "libGLEW compilation failed!"; exit 1; }
sudo make install || { print_error "libGLEW installation failed!"; exit 1; }
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "libGLEW ${VER_libGLEW} installed successfully"

print_section "Building NLOHMANN JSON ${VER_NLOHMANN}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://github.com/nlohmann/json/archive/refs/tags/v${VER_NLOHMANN}.tar.gz
tar -xf v${VER_NLOHMANN}.tar.gz
mkdir json-${VER_NLOHMANN}/build
cd json-${VER_NLOHMANN}/build
cmake .. -DJSON_BuildTests=Off
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "NLOHMANN JSON ${VER_NLOHMANN} installed successfully"

print_section "Building OpenEXR ${VER_OPENEXR}"

cd ${TMP_XSTUDIO_BUILD_DIR}
git clone https://github.com/AcademySoftwareFoundation/openexr.git
cd openexr/
git checkout ${VER_OPENEXR}
mkdir build
cd build
cmake .. -DOPENEXR_INSTALL_TOOLS=Off -DBUILD_TESTING=Off
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "OpenEXR ${VER_OPENEXR} installed successfully"

print_section "Building ActorFramework ${VER_ACTOR}"

cd ${TMP_XSTUDIO_BUILD_DIR}
git clone https://github.com/actor-framework/actor-framework
cd actor-framework
git checkout ${VER_ACTOR}

# Clean any previous build
rm -rf build
mkdir build
cd build

# Configure with CMake (not ./configure)
cmake .. \
	-DCMAKE_INSTALL_PREFIX=/usr/local \
	-DCMAKE_BUILD_TYPE=Release \
	-DCAF_ENABLE_EXAMPLES=OFF \
	-DCAF_ENABLE_TESTING=OFF \
	-DCAF_ENABLE_TOOLS=OFF

if [ $? -ne 0 ]; then
	print_error "ActorFramework CMake configuration failed!"
	exit 1
fi

make -j${JOBS}
if [ $? -ne 0 ]; then
	print_error "ActorFramework compilation failed!"
	exit 1
fi

sudo make install
if [ $? -ne 0 ]; then
	print_error "ActorFramework installation failed!"
	exit 1
fi

sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

# Verify installation
if [ -f "/usr/local/lib/libcaf_core.so" ] || [ -f "/usr/local/lib64/libcaf_core.so" ]; then
	print_success "ActorFramework ${VER_ACTOR} installed successfully"
else
	print_error "ActorFramework installation verification failed!"
	exit 1
fi

print_section "Building OpenColorIO ${VER_OCIO2}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://github.com/AcademySoftwareFoundation/OpenColorIO/archive/refs/tags/v${VER_OCIO2}.tar.gz
tar -xf v${VER_OCIO2}.tar.gz
cd OpenColorIO-${VER_OCIO2}/
mkdir build
cd build
cmake -DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_TESTS=OFF -DOCIO_BUILD_GPU_TESTS=OFF ../
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "OpenColorIO ${VER_OCIO2} installed successfully"

print_section "Building SPDLOG ${VER_SPDLOG}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://github.com/gabime/spdlog/archive/refs/tags/v${VER_SPDLOG}.tar.gz
tar -xf v${VER_SPDLOG}.tar.gz
cd spdlog-${VER_SPDLOG}
mkdir build
cd build
cmake .. -DSPDLOG_BUILD_SHARED=On
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "SPDLOG ${VER_SPDLOG} installed successfully"

print_section "Building FMTLIB ${VER_FMTLIB}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://github.com/fmtlib/fmt/archive/refs/tags/${VER_FMTLIB}.tar.gz
tar -xf ${VER_FMTLIB}.tar.gz
cd fmt-${VER_FMTLIB}/
mkdir build
cd build
cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=1 -DFMT_DOC=Off -DFMT_TEST=Off
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "FMTLIB ${VER_FMTLIB} installed successfully"

print_section "Building OpenTimelineIO ${VER_OpenTimelineIO}"

cd ${TMP_XSTUDIO_BUILD_DIR}
git clone https://github.com/AcademySoftwareFoundation/OpenTimelineIO.git
cd OpenTimelineIO
git checkout ${VER_OpenTimelineIO}
mkdir build
cd build
cmake -DOTIO_PYTHON_INSTALL=ON -DOTIO_DEPENDENCIES_INSTALL=OFF -DOTIO_FIND_IMATH=ON ..
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "OpenTimelineIO ${VER_OpenTimelineIO} installed successfully"

print_section "Building NASM ${VER_NASM}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://www.nasm.us/pub/nasm/releasebuilds/${VER_NASM}/nasm-${VER_NASM}.tar.bz2
tar -xf nasm-${VER_NASM}.tar.bz2
cd nasm-${VER_NASM}
./autogen.sh
./configure
make -j${JOBS}
sudo make install
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "NASM ${VER_NASM} installed successfully"

print_section "Building YASM ${VER_YASM}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://www.tortall.net/projects/yasm/releases/yasm-${VER_YASM}.tar.gz
tar -xf yasm-${VER_YASM}.tar.gz
cd yasm-${VER_YASM}
./configure --prefix="/usr/local"
make -j${JOBS}
sudo make install
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "YASM ${VER_YASM} installed successfully"

print_section "Building x264 ${VER_x264}"

cd ${TMP_XSTUDIO_BUILD_DIR}
git clone --branch ${VER_x264} --depth 1 https://code.videolan.org/videolan/x264.git
cd x264/
./configure --enable-shared --enable-pic
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "x264 ${VER_x264} installed successfully"

print_section "Building x265 ${VER_x265}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://bitbucket.org/multicoreware/x265_git/downloads/x265_${VER_x265}.tar.gz
tar -xf x265_${VER_x265}.tar.gz
cd x265_${VER_x265}/build/linux/
cmake -G "Unix Makefiles" -DENABLE_SHARED=ON ../../source
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "x265 ${VER_x265} installed successfully"

print_section "Building FDK-AAC"

cd ${TMP_XSTUDIO_BUILD_DIR}
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --enable-shared
make -j${JOBS}
sudo make install
sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "FDK-AAC installed successfully"

print_section "Building FFmpeg ${VER_FFMPEG}"

cd ${TMP_XSTUDIO_BUILD_DIR}
wget https://ffmpeg.org/releases/ffmpeg-${VER_FFMPEG}.tar.bz2
tar -xf ffmpeg-${VER_FFMPEG}.tar.bz2
cd ffmpeg-${VER_FFMPEG}/
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
./configure \
	--prefix=/usr/local \
	--extra-libs=-lpthread \
	--extra-libs=-lm \
	--enable-gpl \
	--enable-libfdk_aac \
	--enable-libfreetype \
	--enable-libmp3lame \
	--enable-libopus \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libx265 \
	--enable-shared \
	--enable-nonfree \
	--enable-pic \
	--disable-vulkan

if [ $? -ne 0 ]; then
	print_error "FFmpeg configure failed!"
	exit 1
fi

make -j${JOBS}
if [ $? -ne 0 ]; then
	print_error "FFmpeg compilation failed!"
	exit 1
fi

sudo make install
if [ $? -ne 0 ]; then
	print_error "FFmpeg installation failed!"
	exit 1
fi

sudo ldconfig
cd ${TMP_XSTUDIO_BUILD_DIR}

print_success "FFmpeg ${VER_FFMPEG} installed successfully"

print_section "Cloning xStudio repository"

cd ${TMP_XSTUDIO_BUILD_DIR}

# Check if xstudio directory already exists
if [ -d "xstudio" ]; then
	print_warning "xstudio directory already exists"
	print_info "Checking if it's a valid git repository..."
    
	if [ -d "xstudio/.git" ]; then
		cd xstudio
		print_info "Updating existing repository..."
		git fetch origin
		git checkout ${VER_XSTUDIO}
		git pull origin ${VER_XSTUDIO}
		print_success "xStudio repository updated"
		cd ${TMP_XSTUDIO_BUILD_DIR}
	else
		print_warning "Existing directory is not a valid git repository"
		read -p "Remove and re-clone? (y/N): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			rm -rf xstudio
			git clone https://github.com/AcademySoftwareFoundation/xstudio.git
			cd xstudio
			git checkout ${VER_XSTUDIO}
			cd ${TMP_XSTUDIO_BUILD_DIR}
			print_success "xStudio repository cloned"
		else
			print_error "Cannot proceed with invalid xstudio directory"
			exit 1
		fi
	fi
else
	git clone https://github.com/AcademySoftwareFoundation/xstudio.git
	cd xstudio
	git checkout ${VER_XSTUDIO}
	cd ${TMP_XSTUDIO_BUILD_DIR}
	print_success "xStudio repository cloned"
fi

###############################
# Qt Detection and Compilation
###############################

print_section "Qt Detection and xStudio Compilation"

# Function to find Qt
find_qt() {
	# First check for official Qt 6.5.3 installation
	local QT_SEARCH_PATHS=(
		"${QT_BASE_PATH}/${QT_VERSION}/gcc_64"
		"${QT_BASE_PATH}/Qt${QT_VERSION}/${QT_VERSION}/gcc_64"
		"${HOME}/Qt/${QT_VERSION}/gcc_64"
		"${HOME}/Qt${QT_VERSION}/${QT_VERSION}/gcc_64"
		"/usr/local/Qt/${QT_VERSION}/gcc_64"
		"/usr/local/Qt-${QT_VERSION}/gcc_64"
		"/opt/qt/${QT_VERSION}/gcc_64"
	)
    
	for path in "${QT_SEARCH_PATHS[@]}"; do
		if [ -d "$path" ] && [ -f "$path/bin/qmake" ]; then
			echo "$path"
			return 0
		fi
	done
    
	# Fallback: Check if system Qt6 is available and compatible
	if command -v qmake6 &> /dev/null; then
		# Use clean library path to avoid conflicts
		local SYSTEM_QT_VER=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_VERSION 2>/dev/null)
		if [[ "$SYSTEM_QT_VER" == 6.5.* ]] || [[ "$SYSTEM_QT_VER" == 6.6.* ]] || [[ "$SYSTEM_QT_VER" == 6.7.* ]]; then
			local SYSTEM_QT=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_INSTALL_PREFIX)
			echo "$SYSTEM_QT"
			return 0
		fi
	fi
    
	return 1
}

QT_PATH=$(find_qt)

if [ -n "$QT_PATH" ] && [ "$AUTO_COMPILE" = true ]; then
	# Determine if using system Qt or official Qt
	if [[ "$QT_PATH" == "/usr"* ]]; then
		print_success "Using system Qt6 at: $QT_PATH"
		# Use clean library path to query Qt version
		QT_ACTUAL_VERSION=$(LD_LIBRARY_PATH=/usr/lib64/qt6/lib:/usr/lib64 qmake6 -query QT_VERSION 2>/dev/null)
	else
		print_success "Using official Qt installation at: $QT_PATH"
		QT_ACTUAL_VERSION=$("${QT_PATH}/bin/qmake" -query QT_VERSION 2>/dev/null)
	fi
    
	print_info "Qt version found: ${QT_ACTUAL_VERSION}"
    
	# Check if Qt version is compatible (6.5.x, 6.6.x, or 6.7.x)
	if [[ "$QT_ACTUAL_VERSION" == 6.5.* ]] || [[ "$QT_ACTUAL_VERSION" == 6.6.* ]] || [[ "$QT_ACTUAL_VERSION" == 6.7.* ]]; then
		print_success "Qt version ${QT_ACTUAL_VERSION} is compatible with xStudio"
		print_section "Compiling xStudio"
        
		# Clean environment before building (remove RV/Autodesk paths)
		print_info "Cleaning build environment (removing RV/Autodesk paths)..."
		export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | tr '\n' ':' | sed 's/:$//')
		export LD_LIBRARY_PATH="/usr/lib64/qt6/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH"
        
		# Set environment for compilation
		export CMAKE_PREFIX_PATH=${QT_PATH}:${CMAKE_PREFIX_PATH}
		export PATH=${QT_PATH}/bin:$PATH
        
		cd ${TMP_XSTUDIO_BUILD_DIR}/xstudio
        
		# Clean previous build
		[ -d "build" ] && rm -rf build
        
		# Create build directory
		mkdir build
		cd build
        
		# Configure with CMake
		print_subsection "Running CMake Configuration"
		cmake .. \
			-DCMAKE_PREFIX_PATH="${QT_PATH}" \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_DOCS=OFF \
			-DBUILD_TESTING=OFF \
			-DCMAKE_INSTALL_PREFIX=/usr/local
        
		if [ $? -eq 0 ]; then
			print_success "CMake configuration completed"
            
			# Build xStudio
			print_subsection "Compiling xStudio (this may take a while...)"
			make -j${JOBS}
            
			if [ $? -eq 0 ]; then
				print_success "xStudio compiled successfully!"
                
				# Optional installation
				echo ""
				read -p "Do you want to install xStudio to /usr/local? (requires sudo) (y/N): " -n 1 -r
				echo
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					sudo make install
					sudo ldconfig
					print_success "xStudio installed to /usr/local"
				fi
                
				# Create desktop entry
				echo ""
				read -p "Do you want to create a desktop entry? (y/N): " -n 1 -r
				echo
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					DESKTOP_FILE="${HOME}/.local/share/applications/xstudio.desktop"
					mkdir -p ${HOME}/.local/share/applications
                    
					cat > ${DESKTOP_FILE} << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=xStudio
Comment=Professional Media Playback and Review
Exec=${TMP_XSTUDIO_BUILD_DIR}/xstudio/build/bin/xstudio %U
Icon=${TMP_XSTUDIO_BUILD_DIR}/xstudio/ui/qml/images/xstudio_logo_256_v1.svg
Terminal=false
Categories=AudioVideo;Video;AudioVideoEditing;
MimeType=video/quicktime;video/mp4;image/exr;image/dpx;
EOF
					chmod +x ${DESKTOP_FILE}
					print_success "Desktop entry created"
				fi
                
				# Create environment script
				ENV_SCRIPT="${HOME}/xstudio_env.sh"
				cat > ${ENV_SCRIPT} << 'ENVEOF'
#!/bin/bash
# xStudio Environment and Launcher

# Remove RV/Autodesk paths that conflict with Qt6
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "Autodesk" | grep -v "RV-" | tr '\n' ':' | sed 's/:$//')

# Set xStudio environment
XSTUDIO_BIN="${HOME}/tmp_build_xstudio/xstudio/build/bin"

export LD_LIBRARY_PATH="/usr/lib64/qt6/lib:${XSTUDIO_BIN}/lib:/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="/usr/lib64/qt6/plugins"
export PYTHONPATH="${XSTUDIO_BIN}/python/lib/python3.9/site-packages:/usr/local/lib/python3.9/site-packages:${PYTHONPATH}"

# Launch xStudio
exec "${XSTUDIO_BIN}/xstudio.bin" "$@"
ENVEOF
				chmod +x ${ENV_SCRIPT}
                
				# Also create a simple alias suggestion
				ALIAS_CMD="alias xstudio='${ENV_SCRIPT}'"
				if ! grep -q "alias xstudio=" ~/.bashrc; then
					echo "" >> ~/.bashrc
					echo "# xStudio launcher" >> ~/.bashrc
					echo "${ALIAS_CMD}" >> ~/.bashrc
					print_success "Added xStudio alias to ~/.bashrc"
				fi
                
				print_section "Build Complete!"
				print_success "xStudio has been successfully built and compiled"
				echo ""
				print_info "To run xStudio:"
				print_info "  Option 1 - Use the launcher script:"
				print_info "    ${ENV_SCRIPT}"
				print_info ""
				print_info "  Option 2 - Use the alias (after reloading shell):"
				print_info "    source ~/.bashrc"
				print_info "    xstudio"
				print_info ""
				print_info "  Option 3 - Run directly from build directory:"
				print_info "    cd ${TMP_XSTUDIO_BUILD_DIR}/xstudio/build/bin"
				print_info "    ./xstudio.bin"
				echo ""
				print_warning "Note: Python warnings about 'opentimelineio' are non-critical"
				print_info "The main xStudio application is fully functional"
                
			else
				print_error "xStudio compilation failed!"
				print_info "Check the log for errors: ${TMP_XSTUDIO_BUILD_LOG}"
			fi
		else
			print_error "CMake configuration failed!"
			print_info "Check the log for errors: ${TMP_XSTUDIO_BUILD_LOG}"
		fi
	else
		print_warning "Qt version ${QT_ACTUAL_VERSION} may not be fully tested with xStudio"
		print_info "xStudio officially supports Qt 6.5.x, 6.6.x, and 6.7.x"
		print_info "You can try compiling anyway, or download Qt 6.5.3 from qt.io"
	fi
else
	if [ "$AUTO_COMPILE" = false ]; then
		print_info "Skipping compilation (--skip-compile flag used)"
	else
		print_warning "Qt ${QT_VERSION} not found"
		print_warning "Please install Qt ${QT_VERSION} first"
		print_info "Follow the instructions at:"
		print_info "https://github.com/AcademySoftwareFoundation/xstudio/blob/main/docs/reference/build_guides/downloading_qt.md"
		echo ""
		print_info "After installing Qt, you can:"
		print_info "1. Re-run this script with Qt path: ${0} /path/to/Qt"
		print_info "2. Or manually compile xStudio:"
		print_info "   cd ${TMP_XSTUDIO_BUILD_DIR}/xstudio"
		print_info "   mkdir build && cd build"
		print_info "   cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/${QT_VERSION}/gcc_64"
		print_info "   make -j${JOBS}"
	fi
fi

print_section "Final Summary"
print_info "Build directory: ${TMP_XSTUDIO_BUILD_DIR}"
print_info "Log file: ${TMP_XSTUDIO_BUILD_LOG}"
print_info "CMake version: $(cmake --version | grep version | awk '{print $3}')"

# Check disk space usage
BUILD_SIZE=$(du -sh ${TMP_XSTUDIO_BUILD_DIR} 2>/dev/null | awk '{print $1}')
print_info "Build directory size: ${BUILD_SIZE}"

if [ -f "${TMP_XSTUDIO_BUILD_DIR}/xstudio/build/bin/xstudio" ]; then
	print_success "xStudio binary available at:"
	print_success "${TMP_XSTUDIO_BUILD_DIR}/xstudio/build/bin/xstudio"
    
	# Offer to clean up build artifacts to save space
	echo ""
	read -p "Clean up build artifacts to save disk space? (keeps xstudio binary) (y/N): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		print_info "Cleaning up build artifacts..."
        
		# Remove source tarballs
		cd ${TMP_XSTUDIO_BUILD_DIR}
		rm -f *.tar.gz *.tar.bz2 *.tgz 2>/dev/null
        
		# Remove build directories (keep installed libraries)
		rm -rf glew-* json-* openexr/ actor-framework/ OpenColorIO-* spdlog-* fmt-* \
		rm -rf OpenTimelineIO/ nasm-* yasm-* x264/ x265_* fdk-aac/ ffmpeg-* 2>/dev/null
        
		NEW_SIZE=$(du -sh ${TMP_XSTUDIO_BUILD_DIR} 2>/dev/null | awk '{print $1}')
		print_success "Cleanup complete. Build directory size: ${NEW_SIZE}"
	fi
else
	print_info "xStudio dependencies built successfully"
	print_info "Compilation pending (Qt installation required)"
fi

# Add reminder about file limits
print_info ""
print_info "Tip: If you see 'Too many open files' errors, run:"
print_info "  ulimit -n 4096"

print_success "Script execution completed!"

