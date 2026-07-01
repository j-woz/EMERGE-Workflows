
/**
   LOOP LOCAL SWIFT
   See README
*/

import assert;
import files;
import io;
import json;
import location;
import random;
import string;
import sys;

// import agent_debug;
import agent;

string cfg_dir      = argp(1);
int    replicates   = string2int(argp(2));
string urbanpop     = argp(3);
string cases        = argp(4);
string result_file  = argp(5);

// Dict of params for exaepi_agent.run()
string p = "{}";

assert(turbine_workers() > 1, "need at least 2 workers!");

location RL = locationFromRank(turbine_workers()-1);

result_log(string filename, string record)
{
  @location=RL python_persist("import result_log",
                              "result_log.do_write(\"%s\", \"%s\")" %
                              (filename, record));
}

// Find all the input files:
file input_cfgs[] = glob(cfg_dir / "*.cfg");
printf("loop-local-replicates: found inputs: " + size(input_cfgs));

foreach input_cfg, idx in input_cfgs
{
  printf("loop-local-replicates: running ExaEpi input %s", filename(input_cfg));

  foreach seed in [0:replicates-1]
  {
    result = agent(idx, filename(input_cfg), seed, urbanpop, cases, p);
    printf("result: '%s'", result);
    result_log(result_file, result);
  }
}
