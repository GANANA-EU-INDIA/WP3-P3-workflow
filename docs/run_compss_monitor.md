# COMPSs Monitor Runner

This document decribe the usage of:
```
tools/run_compss_monitor.sh
```

## Overview

A convenience script for running the COMPSs Monitor locally by:
1. Verifying Docker availability and pulling the COMPSs image
2. Mounting the remote `.COMPSs` directory via SSHFS
3. Starting the COMPSs Monitor in a Docker container

## Prerequisites

- **Docker** — installed and running
- **SSHFS** — installed on your system
- **SSH access** — must have previously connected to the cluster (host key accepted)

## Usage

In your local machine, when a PyCOMPSs workflow is running remotely, run the script as:
```bash
./tools/run_compss_monitor.sh <cluster> <remote_parent_path> [local_path]
```
If the script is not executable, use `chmod +x ./tools/run_compss_monitor.sh`.

### Arguments

| Argument | Description |
|---|---|
| `cluster` | SSH alias configured in `~/.ssh/config` |
| `remote_parent_path` | Remote directory where `.COMPSs` resides (without `/.COMPSs` suffix) |
| `local_path` *(optional)* | Local mount point (default: `~/.COMPSs`) |

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
docker stop compss-monitor   # Container auto-removes on stop
fusermount -u ~/.COMPSs       # Unmount remote directory
```

## More Info

[COMPSs Monitor Documentation](https://compss-doc.readthedocs.io/en/latest/Sections/04_Ecosystem/02_Monitor/02_Supercomputer.html)
