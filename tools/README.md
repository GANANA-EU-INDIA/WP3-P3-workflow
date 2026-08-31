# tools/

Scripts for managing the COMPSs ecosystem.

- **`run_compss_monitor.sh`** — To run on your local machine. Start/stop a COMPSs monitor container, mounting a remote `.COMPSs` directory via SSHFS. Uses docker (default) or podman (auto-detected fall-back). For more info, see the [COMPSs documentation on monitoring](https://compss-doc.readthedocs.io/en/stable/Sections/04_Ecosystem/02_Monitor.html).
