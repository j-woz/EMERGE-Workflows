
/**
   LOOP GLOB SWIFT
   See README
*/

import files;
import io;
import random;
import string;
import sys;

// import agent_debug;
import agent;

string template_cfg = argp(1);
int    total        = string2int(argp(2));

// Dict of params for exaepi_agent.run()
string p = "{}";

foreach idx in [0:total-1]
{
  int seed = randint(0, 10*1000*1000);
  (o_file, e_file) = agent(idx, template_cfg, seed, p);
}
