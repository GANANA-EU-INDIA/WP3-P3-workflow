# COMPSs Monitor Runner

This document describes the usage of:

```
tools/run_compss_monitor.sh
```

!!! info
    Based on the [COMPSs Monitor Documentation](https://compss-doc.readthedocs.io/en/latest/Sections/04_Ecosystem/02_Monitor/02_Supercomputer.html)

## Overview

A convenience script for running the COMPSs Monitor locally by:

1. Detecting container runtime (Docker/Podman) and pulling the COMPSs image
2. Mounting the remote `.COMPSs` directory via SSHFS
3. Starting the COMPSs Monitor in a Docker container

## Prerequisites

- **Container runtime** — Docker or Podman installed and running
- **SSHFS** — installed on your system
- **SSH access** — must have previously connected to the cluster (host key accepted)

## Usage

In your local machine, when a PyCOMPSs workflow is running remotely, run the script as:

```bash
./tools/run_compss_monitor.sh <cluster> <remote_parent_path> [local_path]
./tools/run_compss_monitor.sh --stop
```

If the script is not executable, use `chmod +x ./tools/run_compss_monitor.sh`.

### Arguments

| Argument                  | Description                                                          |
| ------------------------- | -------------------------------------------------------------------- |
| `cluster`                 | SSH alias configured in `~/.ssh/config`                              |
| `remote_parent_path`      | Remote directory where `.COMPSs` resides (without `/.COMPSs` suffix) |
| `local_path` _(optional)_ | Local mount point (default: `~/.COMPSs`)                             |
| `--stop`                  | Stop the monitor container and unmount SSHFS                         |

### Examples

```bash
./tools/run_compss_monitor.sh leonardo /leonardo_scratch/large/userinternal/lsalicar/WP3-P3-workflow
./tools/run_compss_monitor.sh dardel /home/user/projects ~/compss-logs
```

## Accessing the Monitor

Once running, access the monitor at:

> **http://localhost:8080/compss-monitor**

Login: `/`

## Stopping

```bash
./tools/run_compss_monitor.sh --stop
# or manually:
docker stop compss-monitor   # Container auto-removes on stop
fusermount -u ~/.COMPSs       # Unmount remote directory
```
