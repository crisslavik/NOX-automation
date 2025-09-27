#!/bin/bash
# NVIDIA Installation Troubleshooting Script for NOX VFX

echo "=== NVIDIA Installation Troubleshooting ==="
echo

echo "🖥️ System Information:"
echo "   OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "   Kernel: $(uname -r)"
echo "   Architecture: $(uname -m)"
echo

echo "🎮 Hardware Detection:"
nvidia_hw=$(lspci | grep -i nvidia)
if [ -n "$nvidia_hw" ]; then
    echo "✅ NVIDIA Hardware Found:"
    echo "$nvidia_hw" | sed 's/^/   /'
else
    echo "❌ No NVIDIA hardware detected"
    echo "   All VGA devices:"
    lspci | grep -i vga | sed 's/^/   /'
    exit 1
fi
echo

echo "📦 Repository Status:"
echo "   Checking NVIDIA repository availability..."
if dnf repolist | grep -q nvidia; then
    echo "✅ NVIDIA repositories configured:"
    dnf repolist | grep nvidia | sed 's/^/   /'
else
    echo "❌ No NVIDIA repositories found"
    echo "   Available repositories:"
    dnf repolist | grep -E "(cuda|nvidia)" | sed 's/^/   /' || echo "   None found"
fi
echo

echo "🔍 Package Availability:"
echo "   Checking NVIDIA driver packages..."
nvidia_packages=$(dnf list available '*nvidia-driver*' 2>/dev/null | grep nvidia-driver | wc -l)
if [ "$nvidia_packages" -gt 0 ]; then
    echo "✅ NVIDIA driver packages available: $nvidia_packages"
    dnf list available 'nvidia-driver*' | head -5 | tail -4 | sed 's/^/   /'
else
    echo "❌ No NVIDIA driver packages available"
    echo "   Try adding NVIDIA repository manually:"
    echo "   dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo"
fi
echo

echo "🔧 Current NVIDIA Status:"
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "✅ nvidia-smi available:"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | sed 's/^/   /' || echo "   nvidia-smi failed (driver not loaded)"
else
    echo "❌ nvidia-smi not available"
fi

if lsmod | grep -q nvidia; then
    echo "✅ NVIDIA kernel modules loaded:"
    lsmod | grep nvidia | sed 's/^/   /'
else
    echo "❌ No NVIDIA kernel modules loaded"
fi
echo

echo "📋 Recommendations:"
if [ -z "$nvidia_hw" ]; then
    echo "1. ❌ No NVIDIA hardware detected - NVIDIA drivers not needed"
elif [ "$nvidia_packages" -eq 0 ]; then
    echo "1. 🔧 Add NVIDIA repository:"
    echo "   dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel$(rpm -E %{rhel})/x86_64/cuda-rhel$(rpm -E %{rhel}).repo"
    echo "   rpm --import https://developer.download.nvidia.com/compute/cuda/repos/rhel$(rpm -E %{rhel})/x86_64/D42D0685.pub"
    echo "2. 🔄 Update package cache: dnf update"
    echo "3. 🎮 Install drivers: dnf install nvidia-driver nvidia-driver-cuda"
elif ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "1. 🎮 Install NVIDIA drivers: dnf install nvidia-driver nvidia-driver-cuda"
    echo "2. 🔄 Reboot system to load drivers"
else
    echo "1. ✅ NVIDIA appears to be working correctly"
    echo "2. 🧪 Test with: nvidia-smi"
fi

echo
echo "🚀 Quick Fix Commands:"
echo "   # Add NVIDIA repo and install:"
echo "   dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo"
echo "   rpm --import https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/D42D0685.pub"
echo "   dnf install nvidia-driver nvidia-driver-cuda xorg-x11-drv-nvidia"
echo "   reboot"
