
"""
EXAEPI AGENT PY

This module:
 * runs the ExaEpi agent in /tmp
 * redirects agent output to /tmp
 * extracts results from /tmp
 * returns results as Python string to workflow.

Our local tree looks like:

WORK_DIR:
/tmp/USER/exaepi/
Contains input data decks and ExaEpi agent executable

RUN_DIRS:
Under the WORK_DIR
/tmp/USER/exaepi/runs/{0000001,0000002,0000003,...}/
A run_dir contains the input.cfg and agent.out and output.dat
"""

import os, sys, time, traceback, json

import cfg_edit

VERBOSE = False

def run(task_id, template_cfg, seed, urbanpop, cases, params):
    """
    Runs ExaEpi agent in local run_dir and extract resulting data
    task_id:      int unique task identifier from workflow logic
    template_cfg: string filename of original cfg (usually in /tmp)
    seed:         int random seed
    urbanpop:     string of urbanpop basename, assumed in work_dir
    cases:        string of cases basename, assumed in work_dir
    params:       dict of other parameters to modify
    return:       string of JSON containing important result values
    """

    user      = os.getenv("USER")
    work_dir   = f"/tmp/{user}/exaepi"
    run_dir    = f"{work_dir}/runs/{task_id:07d}"
    # ExaEpi input file to generate and run:
    input_cfg = f"{run_dir}/input.cfg"
    # stdout/stderr from ExaEpi agent:
    agent_out = f"{run_dir}/agent.out"

    verbose("exaepi_agent: template_cfg: " + template_cfg)
    verbose("exaepi_agent: input_cfg:    " + input_cfg)

    os.makedirs(run_dir, exist_ok=True)

    cfg_id = cfg_edit_checked(template_cfg, run_dir, seed,
                              f"{work_dir}/{urbanpop}",
                              f"{work_dir}/{cases}",
                              params, input_cfg)

    # print("PATH: " + os.getenv("PATH"))

    start = time.time()
    run_exaepi(work_dir, run_dir, input_cfg, agent_out)
    stop  = time.time()

    # result: dict of JSON
    result = get_results(run_dir)
    # Add some additional metadata:
    add_metadata(result, task_id, cfg_id, params, seed, start, stop)

    # Convert dict of JSON to string for Swift/T:
    s = format_json(result)
    return s


def cfg_edit_checked(template_cfg, run_dir, seed, urbanpop, cases,
                     params, input_cfg):
    """ Do cfg_edit, crash on Exceptions """
    try:
        cfg_id = cfg_edit.process(template_cfg, run_dir, seed,
                                  urbanpop, cases, params, input_cfg)
    except Exception as e:
        print("exaepi_agent.run(): Exception in cfg_edit!")
        print("exaepi_agent.run(): " + str(e))
        print("", flush=True)
        t = traceback.format_exc()
        print(t)
        print("", flush=True)
        exit(1)
    return cfg_id


def run_csv_lines(idx, template_cfg, seed, urbanpop, cases, lines):
    """
    Runs ExaEpi agent in local run_dir and extract data
    See run() for most parameters
    params:       CSV lines of parameters to modify
    return:       string of JSON containing key output values
    """

    params = lines2params(lines)
    return run(idx, template_cfg, seed, urbanpop, cases, params)


def run_str_dict(idx, template_cfg, seed,
                 urbanpop, cases, str_dict):
    """
    Runs ExaEpi agent in local run_dir and extract data
    See run() for most parameters
    str_dict:  string of JSON dict with more parameters for eval()
    return:    string of JSON containing key output values
    """

    params = eval(str_dict)
    return run(idx, template_cfg, seed, urbanpop, cases, params)


def lines2params(lines):
    """
    Parse the CSV lines into a dict
    lines: 2 lines separated by NL, a CSV header and the CSV data
    """
    import csv
    from io import StringIO
    # pair = lines.split('\n')
    # assert(len(pair) == 2)
    fp = StringIO(lines)
    reader = csv.reader(fp)
    data_list = list(reader)
    assert len(data_list) == 2
    # headers = pair[0].split(',')
    # values  = pair[1].split(',')
    (headers, values) = data_list
    assert len(headers) == len(values), \
        ("mismatch: headers=%i values=%i" %
         (len(headers), len(values)))
    params = {}
    # print("headers: " + str(headers))
    for header, value in zip(headers, values):
        params[header] = value

    return params


def run_exaepi(work_dir, run_dir, input_cfg, agent_out):
    import subprocess
    agent = work_dir + "/agent"
    check_exes(work_dir)

    cmd = ["mpiexec", "-n", "1", "-launcher", "fork", "affinity.sh",
           agent, input_cfg]
    # print("cmd: " + str(cmd), flush=True)

    environment = setup_environment()

    touch(agent_out)
    with open(agent_out, "r+") as fp:
        child = subprocess.run(cmd,
                               cwd = run_dir,
                               env = environment,
                               stdout=fp # ,
                               # stderr=subprocess.STDOUT
                               )
        check_child(child, fp)


# Did we check the executables and set the x bit?
chmod_complete = False


def check_exes(work_dir):
    """ Check executables """
    global chmod_complete
    if chmod_complete: return

    for exe in [ "agent", "affinity.sh" ]:
        exe = work_dir + "/" + exe
        if not os.path.exists(exe):
            print("exaepi_agent.py: could not find exe: '%s'" % exe,
                  flush=True)
            exit(1)
        os.chmod(exe, 0o755)
    chmod_complete = True


def setup_environment():
    environment = os.environ.copy()
    if "PMIX_NAMESPACE" in environment:
        del environment["PMIX_NAMESPACE"]
    environment["PMIX_MCA_psec"] = "none"
    environment["RANK"] = os.getenv("ADLB_RANK_SELF")
    return environment


def touch(agent_out):
    """ Create this file so we can reopen it in R/W (r+) mode """
    with open(agent_out, "w") as fp: pass


def check_child(child, fp):
    if child.returncode == 0: return
    print("exaepi_agent.run_exaepi(): agent exit code: %i" %
          child.returncode,
          flush=True)
    fp.seek(0)
    text = fp.read()
    print(text)
    exit(1)
    # print("ExaEpi agent OK.", flush=True)


def get_results(run_dir):
    """ Read ExaEpi agent output and stuff into a JSON string """
    import json
    agent_out = f"{run_dir}/agent.out"
    agent_dat = f"{run_dir}/output.dat"
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

    with open(agent_dat, "r") as fp:
        output_contents = fp.read()

    result = {"day_final":  day_final,
              "infected":   infecteds,
              "deaths":     deaths,
              "output_dat": output_contents}

    return result


def add_metadata(result, task_id, cfg_id, params, seed, start, stop):
    # task_id: a unique integer generated by the workflow:
    result["task_id"] = task_id
    # cfg_id: an integer stored in the input cfg file (or None):
    result["cfg_id"] = cfg_id
    # params_id: an integer stored in the params specification:
    if "params_id" in params:
        result["params_id"] = int(params["params_id"])
    # the random seed used:
    result["seed"]  = seed
    result["start"] = start
    result["stop"]  = stop


def format_json(D):
    """ Format as valid JSON with indentation for readability """
    return json.dumps(D, indent=2) + "\n"


def run_fake(idx, template_cfg, seed, urbanpop, cases, params):
    """ TODO: Generate fake ExaEpi output """
    pass


def verbose(msg):
    if VERBOSE:
        print(msg, flush=True)

"""
    L = os.listdir("/tmp/wozniak/exaepi")
    print("TMP: " + str(L))

    L = os.listdir(run_dir)
    print("RUN_DIR: " + str(L))
"""
