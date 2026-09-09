#!/usr/bin/env bash
# COMPSs Monitor Runner Script, locally
# This script helps users run the COMPSs monitor locally by:
# 1. Detecting container runtime (docker/podman) and pulling the COMPSs image
# 2. Mounting remote .COMPSs directory via SSHFS
# 3. Starting the COMPSs monitor in a container

set -e

# Configuration
COMPSS_IMAGE="compss/compss:3.4"
COMPSS_PORT="8080"
# Prefer docker, fall back to podman (daemonless, rootless by default)
CONTAINER_CMD=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect available container runtime (prefer docker, fall back to podman)
setup_container_cmd() {
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        CONTAINER_CMD="docker"
    elif command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
    else
        print_error "No container runtime found. Please install Docker or Podman."
        exit 1
    fi
    print_success "Using $CONTAINER_CMD"
}

# Pull COMPSs image if not present
pull_compss_image() {
    print_info "Checking for image: $COMPSS_IMAGE"
    
    if $CONTAINER_CMD image inspect "$COMPSS_IMAGE" &> /dev/null; then
        print_success "Image already exists locally"
        print_info "To use a different version, modify COMPSS_IMAGE in the script configuration"
    else
        print_info "Pulling $COMPSS_IMAGE..."
        $CONTAINER_CMD pull "$COMPSS_IMAGE"
        print_success "Image pulled successfully"
    fi
}

# Check if SSHFS is installed
check_sshfs() {
    print_info "Checking SSHFS installation..."
    
    if ! command -v sshfs &> /dev/null; then
        print_error "SSHFS is not installed. Please install SSHFS first."
        echo "On Ubuntu/Debian: sudo apt-get install sshfs"
        echo "On Fedora: sudo dnf install sshfs"
        echo "On Arch: sudo pacman -S sshfs"
        echo "On macOS: brew install sshfs"
        exit 1
    fi
    
    print_success "SSHFS is installed"
}

# Check SSH configuration for cluster
check_ssh_config() {
    local cluster=$1
    
    print_info "Checking SSH configuration for cluster: $cluster"
    echo ""
    echo "Verifying that you have previously connected to this cluster..."
    echo "The script checks ~/.ssh/config and ~/.ssh/known_hosts for: $cluster"
    echo ""
    
    # Check if cluster is in .ssh/config
    local config_file="$HOME/.ssh/config"
    local known_hosts_file="$HOME/.ssh/known_hosts"
    local found_in_config=false
    local found_in_known_hosts=false
    
    if [ -f "$config_file" ] && grep -q "^Host $cluster" "$config_file" 2>/dev/null; then
        found_in_config=true
        print_info "Found '$cluster' in ~/.ssh/config"
    fi
    
    if [ -f "$known_hosts_file" ] && grep -q "$cluster" "$known_hosts_file" 2>/dev/null; then
        found_in_known_hosts=true
        print_info "Found '$cluster' in ~/.ssh/known_hosts"
    fi
    
    echo ""
    
    if [ "$found_in_config" = false ] && [ "$found_in_known_hosts" = false ]; then
        print_error "Cluster '$cluster' not found in SSH configuration"
        echo ""
        echo -e "${RED}ERROR: You need to connect to the cluster at least once before using this script.${NC}"
        echo ""
        echo "To fix this, please:"
        echo "  1. Manually connect to the cluster: ssh $cluster"
        echo "  2. Accept the host key if prompted"
        echo "  3. Optionally, add an entry to ~/.ssh/config for easier access"
        echo ""
        echo "Example ~/.ssh/config entry:"
        echo "Host $cluster"
        echo "    HostName <cluster-hostname>"
        echo "    User <your-username>"
        echo "    IdentityFile ~/.ssh/id_rsa"
        echo ""
        exit 1
    fi
    
    # Verify SSH connectivity
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$cluster" "exit" 2>/dev/null; then
        print_error "Cannot establish SSH connection to '$cluster'"
        echo ""
        echo -e "${RED}ERROR: SSH connection failed. Please check:${NC}"
        echo "  - Your network connection"
        echo "  - SSH key configuration"
        echo "  - Cluster availability"
        echo ""
        echo "Try: ssh $cluster"
        exit 1
    fi
    
    print_success "SSH configuration and connectivity verified for '$cluster'"
}

# Mount remote .COMPSs directory
mount_compss() {
    local cluster=$1
    local remote_parent_path=$2
    local local_path=$3
    
    print_info "Mounting remote .COMPSs directory..."
    echo "  Cluster: $cluster"
    echo "  Remote path: ${cluster}:${remote_parent_path}/.COMPSs"
    echo "  Local path: $local_path"
    echo ""
    
    # Create local directory if it doesn't exist
    if [ ! -d "$local_path" ]; then
        print_info "Creating local directory: $local_path"
        mkdir -p "$local_path"
    fi
    
    # Check if already mounted
    if mountpoint -q "$local_path" 2>/dev/null; then
        print_warning "Directory is already mounted. Unmounting first..."
        fusermount -u "$local_path" 2>/dev/null || umount "$local_path" 2>/dev/null || true
        sleep 1
    fi
    
    # Mount the remote directory
    print_info "Mounting via SSHFS..."
    sshfs -o allow_other "${cluster}:${remote_parent_path}/.COMPSs" "$local_path"
    
    if [ $? -eq 0 ]; then
        print_success "Successfully mounted .COMPSs directory"
    else
        print_error "Failed to mount .COMPSs directory"
        exit 1
    fi
}

# Start COMPSs monitor in container
start_monitor() {
    local local_path=$1
    
    print_info "Starting COMPSs monitor in $CONTAINER_CMD container..."
    echo ""
    echo "Container configuration:"
    echo "  Image: $COMPSS_IMAGE"
    echo "  Port: http://localhost:$COMPSS_PORT/compss-monitor"
    echo "  Volume: $local_path:/.COMPSs"
    echo ""
    
    # Check if container is already running
    if $CONTAINER_CMD ps --format '{{.Names}}' | grep -q "compss-monitor"; then
        print_warning "A container named 'compss-monitor' is already running"
        echo ""
        print_success "COMPSs monitor is already running!"
        echo "Access it at: http://localhost:$COMPSS_PORT/compss-monitor"
        echo "Login: /"
        echo ""
        echo "To restart, stop the container first:"
        echo "  $CONTAINER_CMD stop compss-monitor"
        return 0
    fi
    
    # Start new container with --rm flag for automatic cleanup
    print_info "Starting $CONTAINER_CMD container..."
    $CONTAINER_CMD run -d \
        --rm \
        --name compss-monitor \
        -p ${COMPSS_PORT}:8080 \
        -v "${local_path}:/.COMPSs" \
        "$COMPSS_IMAGE" \
        tail -f /dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Container started successfully (will auto-remove on stop)"
        
        # Start the monitor inside the container
        print_info "Starting COMPSs monitor service..."
        $CONTAINER_CMD exec compss-monitor /etc/init.d/compss-monitor start
        
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}COMPSs Monitor is now running!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "Access the monitor at:"
        echo -e "${BLUE}http://localhost:${COMPSS_PORT}/compss-monitor${NC}"
        echo ""
        echo "Login: /"
        echo ""
        echo "To stop the monitor (container will auto-remove):"
        echo "  $CONTAINER_CMD stop compss-monitor"
        echo ""
        echo "To unmount the remote directory when done:"
        echo "  fusermount -u $local_path"
        echo "  # or: umount $local_path"
        echo ""
    else
        print_error "Failed to start $CONTAINER_CMD container"
        exit 1
    fi
}

# Stop COMPSs monitor and unmount SSHFS
stop_monitor() {
    print_info "Stopping COMPSs monitor..."
    
    # Check if container is running
    if ! $CONTAINER_CMD ps --format '{{.Names}}' | grep -q "^compss-monitor$"; then
        print_warning "No running container named 'compss-monitor' found"
        print_info "Nothing to stop"
        return 0
    fi
    
    # Stop the container (--rm flag means it auto-removes)
    $CONTAINER_CMD stop compss-monitor
    print_success "Container 'compss-monitor' stopped"
    
    # Find and unmount SSHFS mount
    print_info "Looking for SSHFS mount to unmount..."
    local mount_path
    mount_path=$(mount | grep sshfs | awk '{print $3}' | head -1)
    
    if [ -z "$mount_path" ]; then
        print_info "No SSHFS mount found (already unmounted or never mounted)"
    else
        print_info "Found SSHFS mount at: $mount_path"
        if fusermount -u "$mount_path" 2>/dev/null; then
            print_success "SSHFS unmounted"
        else
            print_warning "Failed to unmount. Try manually: fusermount -u $mount_path"
        fi
    fi
    
    echo ""
    print_success "COMPSs monitor stopped"
}

# Display usage information
usage() {
    echo "Usage: $0 <cluster> <remote_parent_path> [local_path]"
    echo "       $0 --detach | --stop"
    echo ""
    echo "Arguments:"
    echo "  cluster            SSH alias for the cluster (configure in ~/.ssh/config)"
    echo "  remote_parent_path Parent directory path where .COMPSs lives (without /.COMPSs)"
    echo "  local_path         Local mount point (default: ~/.COMPSs)"
    echo ""
    echo "Options:"
    echo "  --detach, --stop   Stop the monitor container and unmount SSHFS"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 leonardo /leonardo_scratch/large/userinternal/lsalicar/WP3-P3-workflow"
    echo "  $0 dardel /home/user/projects ~/compss-logs"
    echo "  $0 --detach"
    echo ""
    echo "This script will:"
    echo "  1. Detect container runtime (docker/podman) and pull image if needed"
    echo "  2. Check SSHFS installation"
    echo "  3. Mount remote .COMPSs directory via SSHFS"
    echo "  4. Start COMPSs monitor in a container"
    echo ""
    echo "More info in the official doc: https://compss-doc.readthedocs.io/en/latest/Sections/04_Ecosystem/02_Monitor/02_Supercomputer.html"
    echo "The monitor will be available at: http://localhost:8080/compss-monitor"
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}COMPSs Monitor Runner${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check for detach/stop flag
    if [[ "$1" == "--detach" || "$1" == "--stop" ]]; then
        setup_container_cmd
        stop_monitor
        exit 0
    fi
    
    # Validate arguments
    if [ $# -lt 2 ]; then
        print_error "Insufficient arguments"
        echo ""
        usage
        exit 1
    fi
    
    local cluster=$1
    local remote_parent_path=$2
    local local_path=${3:-~/.COMPSs}
    
    # Remove trailing slash from remote path if present
    remote_parent_path="${remote_parent_path%/}"
    
    # Expand tilde in local path
    local_path="${local_path/#\~/$HOME}"
    
    print_info "Configuration:"
    echo "  Cluster: $cluster"
    echo "  Remote parent path: $remote_parent_path"
    echo "  Local mount path: $local_path"
    echo ""
    
    # Step 1: Detect container runtime
    setup_container_cmd
    echo ""
    
    # Step 2: Pull COMPSs image
    pull_compss_image
    echo ""
    
    # Step 3: Check SSHFS
    check_sshfs
    echo ""
    
    # Step 4: Check SSH configuration
    check_ssh_config "$cluster"
    echo ""
    
    # Step 5: Mount remote directory
    mount_compss "$cluster" "$remote_parent_path" "$local_path"
    echo ""
    
    # Step 6: Start monitor
    start_monitor "$local_path"
}

# Run main function with all arguments
main "$@"
