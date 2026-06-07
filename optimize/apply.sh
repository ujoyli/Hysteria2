#!/bin/bash
# Apply kernel and network optimizations for Hysteria2
# Usage: sudo bash apply.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Applying kernel parameters ==="
cp "$SCRIPT_DIR/sysctl-hysteria.conf" /etc/sysctl.d/99-hysteria.conf
sysctl -p /etc/sysctl.d/99-hysteria.conf

echo "=== Setting fq qdisc for BBR ==="
IFACE=$(ip route show default | awk '{print $5}' | head -1)
tc qdisc replace dev "$IFACE" root fq
echo "Applied fq qdisc on $IFACE"

# Persist fq qdisc across reboots
PERSIST_DIR="/etc/networkd-dispatcher/routable.d"
if [ -d "$PERSIST_DIR" ]; then
    cat > "$PERSIST_DIR/50-fq-qdisc.sh" << EOF
#!/bin/bash
tc qdisc replace dev $IFACE root fq
EOF
    chmod +x "$PERSIST_DIR/50-fq-qdisc.sh"
    echo "Persisted fq qdisc via networkd-dispatcher"
fi

echo "=== Restarting Hysteria2 ==="
systemctl restart hysteria-server
sleep 1
systemctl is-active hysteria-server && echo "Hysteria2 is running" || echo "ERROR: Hysteria2 failed to start"

echo "=== Done ==="
