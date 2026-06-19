
import os
import subprocess

import cfg_edit


def run(idx, template_cfg, seed, params):
    """
    idx:       int index
    input_cfg: string filename of original cfg (usually in /tmp)
    seed:      int random seed
    params:    dict of other parameters to modify
    """

    user = os.getenv("USER")
    rundir = f"/tmp/{user}/exaepi/{idx}"
    input_cfg = rundir + "/input.cfg"
    os.make_dirs(rundir)
    cfg_edit.run(template_cfg, rundir, seed, params, input_cfg)
    # subprocess.run("agent ...")
