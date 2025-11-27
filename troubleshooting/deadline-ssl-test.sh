#!/bin/bash
# Deadline RCS SSL Connection Troubleshooting Script

echo "=== Deadline RCS SSL Connection Diagnostics ==="
echo ""

RCS_SERVER="192.168.11.16"
RCS_PORT="4433"
DEADLINE_DIR="/opt/Thinkbox/Deadline10"

echo "1. Testing basic connectivity to RCS server..."
curl -k -v "https://${RCS_SERVER}:${RCS_PORT}" 2>&1 | grep -E "(Connected|SSL|TLS|Server certificate)"
echo ""

echo "2. Testing with different TLS versions..."
echo "   TLS 1.2:"
curl -k --tlsv1.2 -v "https://${RCS_SERVER}:${RCS_PORT}" 2>&1 | grep -E "(SSL connection|established)"
echo "   TLS 1.3:"
curl -k --tlsv1.3 -v "https://${RCS_SERVER}:${RCS_PORT}" 2>&1 | grep -E "(SSL connection|established)"
echo ""

echo "3. Current Deadline configuration:"
if [ -f "${DEADLINE_DIR}/bin/deadlinecommand" ]; then
    export HOME=/root
    ${DEADLINE_DIR}/bin/deadlinecommand GetIniFileSetting ConnectionType
    ${DEADLINE_DIR}/bin/deadlinecommand GetIniFileSetting ProxyRoot
    ${DEADLINE_DIR}/bin/deadlinecommand GetIniFileSetting ProxyUseSSL
    ${DEADLINE_DIR}/bin/deadlinecommand GetIniFileSetting ProxyValidateCertificate
    ${DEADLINE_DIR}/bin/deadlinecommand GetIniFileSetting ProxySSLCertificate
else
    echo "Deadline not installed at ${DEADLINE_DIR}"
fi
echo ""

echo "4. Checking for deadline.ini files:"
find /root /home -name "deadline.ini" 2>/dev/null | while read ini; do
    echo "   $ini:"
    grep -E "(ProxyRoot|ProxyUseSSL|ProxyValidateCertificate)" "$ini" 2>/dev/null
done
echo ""

echo "5. Testing connection with deadlinecommand:"
if [ -f "${DEADLINE_DIR}/bin/deadlinecommand" ]; then
    export HOME=/root
    ${DEADLINE_DIR}/bin/deadlinecommand GetRepositoryVersion 2>&1 | head -20
fi
