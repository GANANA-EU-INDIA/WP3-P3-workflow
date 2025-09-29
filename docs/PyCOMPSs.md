## Miscellaneous notes

- the `bin` argument `working_dir` can lead to problems even if the file passed as arguments of the function are described by absolute paths. The example is using `pdb_delhetatom`, in which specifying the working dir as the parent to the input and output directories, messes up the paths eventhough in the `main` function these are passed as `str` of the absolute, resolved, path. (still don't know why).
- the explicitely defined arguments to a binary inside the `binary` decorator is much more cleaner than defining arguments through the python function arguments.
- shell scripts can be used to wrap another program/binary that does not a flag/way to specify which and how many files it produces (nor a directory where it outputs).
- the `contraint` decorator instruct the task on the OMP threads to allocate for the task. This implies that it set the `OMP_NUM_THREADS` environmental variable that, otherwise, cannot be exported before the `enqueue_compss` invocation.
- when using `mdrun` you should always check the `mdp` file that starts the simulation to know which file will be produced. A common error is the fact that, [if you don't specify the keywords `nstxout` and similar, you won't get a trajectory file](https://gromacs.bioexcel.eu/t/no-trajectory-trr-file-produced/6964). Only a checkpoint file will be produced. Hence, if in the workflow you specified to output a `trr` file but it does not appear, COMPSs will exit with an error, causing you headaches.
- To use the **monitor**, please refer to [this very hidden part of the documentation](https://compss-doc.readthedocs.io/en/3.3.3/Sections/03_Execution_Environments/03_Deployments/01_Master_worker/02_Supercomputers/05_COMPSs_monitor.html)
- COMPSs search for **checkpoints** and loads them! It avoids running the same task multiple times
   - you have to pass to the `enqueue_compss` the checkpoint related flags, specifically `checkpoint_folder`.
   - you can run the workflow one time configuring checkpoints. When you run it again with the same checkpoint folder config you'll see in the `runtime.log` (inside `.COMPSs` dir) the loading of the checkpoints.
   - in the summary, obtained through the `--summary` flag, you can see that in the second run no computations are performed.
   - one **unresolved issues** (as in the 3.3.3 version): in the second identical run, the runtime waits indefinetly with the line `[LAUNCH_COMPSS] Waiting for application completion` in `compss-[id-job].out`.
- `print` statements in the main code that write on the STOUT, are catched by the `job-[JOBID].out` files.
