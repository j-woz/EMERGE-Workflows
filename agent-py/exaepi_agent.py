
import os, sys, traceback

import cfg_edit


def run(idx, template_cfg, seed, urbanpop, cases, params):
    """
    Runs ExaEpi agent in local rundir
    idx:       int index
    input_cfg: string filename of original cfg (usually in /tmp)
    seed:      int random seed
    urbanpop:  string of urbanpop basename, assumed to be in workdir
    params:    dict of other parameters to modify
    """

    user      = os.getenv("USER")
    workdir   = f"/tmp/{user}/exaepi"
    rundir    = f"{workdir}/{idx}"
    # ExaEpi input file to generate and run:
    input_cfg = f"{rundir}/input.cfg"
    # stdout/stderr from ExaEpi agent:
    agent_out = f"{rundir}/agent.out"

    os.makedirs(rundir, exist_ok=True)
    try:
        cfg_edit.process(template_cfg, rundir, seed,
                         f"{workdir}/{urbanpop}",
                         f"{workdir}/{cases}",
                         params, input_cfg)
    except Exception as e:
        print("exaepi_agent.run(): Exception in cfg_edit!")
        print("exaepi_agent.run(): " + str(e))
        print("", flush=True)
        t = traceback.format_exc()
        print(t)
        print("", flush=True)
        exit(1)

    run_exaepi(workdir, rundir, input_cfg, agent_out)

    result = get_results(agent_out)
    result["idx"]  = idx
    result["seed"] = seed
    return str(result)


def run_exaepi(workdir, rundir, input_cfg, agent_out):
    import subprocess
    cmd = ["mpiexec", workdir + "/agent", input_cfg]
    with open(agent_out, "w") as fp:
        child = subprocess.run(cmd,
                               cwd = rundir,
                               stdout=fp,
                               stderr=subprocess.STDOUT)
    if child.returncode != 0:
        print("exaepi_agent.run(): exit code: %i" % child.returncode,
              flush=True)
        exit(1)
    # print("ExaEpi agent OK.", flush=True)


def get_results(agent_out):
    day_final = 0
    infecteds = []
    deaths    = []
    with open(agent_out, "r") as fp:
        while True:
            line = fp.readline()
            if line == "": break
            if line.startswith("[Day "):
                tokens   = line.split(" ")
                day      = int(tokens[1])
                # Drop trailing semicolon:
                infected = int(tokens[5][0:-1])
                dead     = int(tokens[7])
                day_final = day
                infecteds.append(infected)
                deaths.append(dead)
    return {"day_final": day_final,
            "infected" : infecteds,
            "deaths"   : deaths}
