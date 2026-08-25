#!/usr/bin/env bash
# COMPSs Monitor Runner Script, locally
# This script helps users run the COMPSs monitor locally by:
# 1. Checking Docker availability and pulling the COMPSs image
# 2. Mounting remote .COMPSs directory via SSHFS
# 3. Starting the COMPSs monitor in a Docker container

set -e

# Configuration
COMPSS_IMAGE="compss/compss:3.4"
COMPSS_PORT="8080"

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

# Check if Docker is installed and running
check_docker() {
    print_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Docker is installed and running"
}

# Pull COMPSs Docker image if not present
pull_compss_image() {
    print_info "Checking for COMPSs Docker image: $COMPSS_IMAGE"
    
    if docker image inspect "$COMPSS_IMAGE" &> /dev/null; then
        print_success "COMPSs image already exists locally"
        print_info "To use a different version, modify COMPSS_IMAGE in the script configuration"
    else
        print_info "Pulling $COMPSS_IMAGE..."
        docker pull "$COMPSS_IMAGE"
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

# Start COMPSs monitor in Docker container
start_monitor() {
    local local_path=$1
    
    print_info "Starting COMPSs monitor in Docker container..."
    echo ""
    echo "Container configuration:"
    echo "  Image: $COMPSS_IMAGE"
    echo "  Port: http://localhost:$COMPSS_PORT/compss-monitor"
    echo "  Volume: $local_path:/.COMPSs"
    echo ""
    
    # Check if container is already running
    if docker ps --format '{{.Names}}' | grep -q "compss-monitor"; then
        print_warning "A container named 'compss-monitor' is already running"
        echo ""
        print_success "COMPSs monitor is already running!"
        echo "Access it at: http://localhost:$COMPSS_PORT/compss-monitor"
        echo "Login: /"
        echo ""
        echo "To restart, stop the container first:"
        echo "  docker stop compss-monitor"
        return 0
    fi
    
    # Start new container with --rm flag for automatic cleanup
    print_info "Starting Docker container..."
    docker run -d \
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
        docker exec compss-monitor /etc/init.d/compss-monitor start
        
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
        echo "  docker stop compss-monitor"
        echo ""
        echo "To unmount the remote directory when done:"
        echo "  fusermount -u $local_path"
        echo "  # or: umount $local_path"
        echo ""
    else
        print_error "Failed to start Docker container"
        exit 1
    fi
}

# Display usage information
usage() {
    echo "Usage: $0 <cluster> <remote_parent_path> [local_path]"
    echo ""
    echo "Arguments:"
    echo "  cluster            SSH alias for the cluster (configure in ~/.ssh/config)"
    echo "  remote_parent_path Parent directory path where .COMPSs lives (without /.COMPSs)"
    echo "  local_path         Local mount point (default: ~/.COMPSs)"
    echo ""
    echo "Example:"
    echo "  $0 leonardo /leonardo_scratch/large/userinternal/lsalicar/WP3-P3-workflow"
    echo "  $0 dardel /home/user/projects ~/compss-logs"
    echo ""
    echo "This script will:"
    echo "  1. Check Docker installation and pull COMPSs image if needed"
    echo "  2. Check SSHFS installation"
    echo "  3. Mount remote .COMPSs directory via SSHFS"
    echo "  4. Start COMPSs monitor in a Docker container"
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
    
    # Step 1: Check Docker
    check_docker
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
