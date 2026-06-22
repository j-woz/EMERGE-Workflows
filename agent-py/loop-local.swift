
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

string template_cfg = argp(1);
int    total        = string2int(argp(2));
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

foreach idx in [0:total-1]
{
  int seed = randint(0, 10*1000*1000);
  result = agent(idx, template_cfg, seed, urbanpop, cases, p);
  printf("result: '%s'", result);
  result_log(result_file, result);
}



/* json_encode_object(["agent.urbanpop_filename"],
                               "urbanpop_nm.bin"); */
