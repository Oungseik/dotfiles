#!/usr/bin/env bash

# System-wide proxy tunnel script for Linux with auto-recovery
# Routes all TCP traffic through a SOCKS5/HTTP proxy on 127.0.0.1:2080

set -e

PROXY_IP="127.0.0.1"
PROXY_PORT="2080"
PROXY_TYPE="socks5"  # Change to "http-connect" if using HTTP proxy
REDSOCKS_PORT="12345"
REDSOCKS_CONF="/tmp/redsocks.conf"
REDSOCKS_PID="/tmp/redsocks.pid"
MONITOR_INTERVAL=10  # Check connection every 10 seconds

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Function to check if redsocks is installed
check_redsocks() {
    if ! command -v redsocks &> /dev/null; then
        echo "redsocks is not installed. Installing..."
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y redsocks
        elif command -v yum &> /dev/null; then
            yum install -y redsocks
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm redsocks
        else
            echo "Please install redsocks manually"
            exit 1
        fi
    fi
}

# Create redsocks configuration with better settings
create_redsocks_config() {
    cat > "$REDSOCKS_CONF" <<EOF
base {
    log_debug = off;
    log_info = on;
    log = "stderr";
    daemon = off;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = $REDSOCKS_PORT;
    ip = $PROXY_IP;
    port = $PROXY_PORT;
    type = $PROXY_TYPE;
}
EOF
}

# Setup iptables rules
setup_iptables() {
    echo "Setting up iptables rules..."
    
    # Create REDSOCKS chain
    iptables -t nat -N REDSOCKS 2>/dev/null || iptables -t nat -F REDSOCKS
    
    # Exclude local traffic
    iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
    
    # Redirect all other TCP traffic to redsocks
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $REDSOCKS_PORT
    
    # Apply REDSOCKS chain to OUTPUT
    iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
    
    echo "iptables rules applied successfully"
}

# Cleanup iptables rules
cleanup_iptables() {
    echo "Cleaning up iptables rules..."
    iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null || true
    iptables -t nat -F REDSOCKS 2>/dev/null || true
    iptables -t nat -X REDSOCKS 2>/dev/null || true
    echo "iptables rules removed"
}

# Check if proxy is accessible
check_proxy() {
    # Try to connect to the proxy port
    timeout 2 bash -c "cat < /dev/null > /dev/tcp/$PROXY_IP/$PROXY_PORT" 2>/dev/null
    return $?
}

# Check if redsocks is running
check_redsocks_running() {
    if [ -f "$REDSOCKS_PID" ]; then
        local pid=$(cat "$REDSOCKS_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Start redsocks process
start_redsocks_process() {
    echo "Starting redsocks..."
    redsocks -c "$REDSOCKS_CONF" &
    local pid=$!
    echo $pid > "$REDSOCKS_PID"
    sleep 2
    
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "redsocks started with PID $pid"
        return 0
    else
        echo "Failed to start redsocks"
        return 1
    fi
}

# Stop redsocks process
stop_redsocks_process() {
    if [ -f "$REDSOCKS_PID" ]; then
        local pid=$(cat "$REDSOCKS_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Stopping redsocks (PID $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$REDSOCKS_PID"
    fi
    pkill -9 redsocks 2>/dev/null || true
}

# Restart redsocks
restart_redsocks() {
    echo "Restarting redsocks..."
    stop_redsocks_process
    sleep 2
    start_redsocks_process
}

# Monitor and auto-restart
monitor_connection() {
    local failure_count=0
    local max_failures=3
    
    while true; do
        sleep $MONITOR_INTERVAL
        
        # Check if proxy is still accessible
        if ! check_proxy; then
            echo "WARNING: Proxy at $PROXY_IP:$PROXY_PORT is not accessible!"
            ((failure_count++))
            
            if [ $failure_count -ge $max_failures ]; then
                echo "ERROR: Proxy unreachable after $max_failures attempts. Stopping..."
                return 1
            fi
            continue
        fi
        
        # Check if redsocks is still running
        if ! check_redsocks_running; then
            echo "WARNING: redsocks process died. Restarting..."
            restart_redsocks
            failure_count=0
            continue
        fi
        
        # Check if we can actually connect through the proxy
        # Temporarily disable iptables, test direct connection, re-enable
        if [ $((RANDOM % 6)) -eq 0 ]; then  # Test every ~60 seconds
            iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null || true
            
            if timeout 5 curl -s --max-time 5 http://detectportal.firefox.com/success.txt > /dev/null 2>&1; then
                : # Connection test passed
            else
                echo "WARNING: Network connectivity issues detected. Restarting redsocks..."
                restart_redsocks
                failure_count=0
            fi
            
            iptables -t nat -A OUTPUT -p tcp -j REDSOCKS 2>/dev/null || true
        fi
        
        # Reset failure count on successful checks
        failure_count=0
    done
}

# Start tunneling with monitoring
start_tunnel() {
    echo "Starting proxy tunnel with auto-recovery..."
    check_redsocks
    
    # Check if proxy is accessible before starting
    if ! check_proxy; then
        echo "ERROR: Cannot connect to proxy at $PROXY_IP:$PROXY_PORT"
        echo "Please make sure your proxy is running."
        exit 1
    fi
    
    create_redsocks_config
    setup_iptables
    start_redsocks_process
    
    echo "Proxy tunnel is active. All TCP traffic is being routed through $PROXY_IP:$PROXY_PORT"
    echo "Monitoring connection and auto-restarting if needed..."
    echo "Press Ctrl+C to stop..."
    
    # Start monitoring
    trap cleanup EXIT
    monitor_connection
}

# Stop tunneling
stop_tunnel() {
    stop_redsocks_process
    cleanup_iptables
    rm -f "$REDSOCKS_CONF" "$REDSOCKS_PID"
    echo "Proxy tunnel stopped"
}

# Cleanup on exit
cleanup() {
    echo ""
    echo "Stopping proxy tunnel..."
    stop_tunnel
}

# Main
case "${1:-start}" in
    start)
        start_tunnel
        ;;
    stop)
        stop_tunnel
        ;;
    restart)
        stop_tunnel
        sleep 2
        start_tunnel
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        echo "  start   - Start the proxy tunnel with monitoring (default)"
        echo "  stop    - Stop the proxy tunnel"
        echo "  restart - Restart the proxy tunnel"
        exit 1
        ;;
esac
