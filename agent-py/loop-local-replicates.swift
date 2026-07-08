
/**
   LOOP LOCAL REPLICATES SWIFT
   See README
*/

import assert;
import files;
import io;
import json;
import location;
import random;
import stats;
import string;
import sys;

// import agent_debug;
import agent;

import csv_get;

string template_cfg = argp(1);
string csv_file     = argp(2);
int    replicates   = string2int(argp(3));
string urbanpop     = argp(4);
string cases        = argp(5);
string result_file  = argp(6);

assert(turbine_workers() >= 3, "need at least 3 workers!");

location RL = locationFromRank(turbine_workers()-1);

result_log(string filename, string record)
{
  // Need triple-quote: record strings contain NLs
  @location=RL
    python_persist("import result_log",
                   "result_log.do_write(\"%s\", \"\"\"%s\"\"\")" %
                   (filename, record));
}

// Find all the input files:

printf("csv_file: " + csv_file);

// CSV_GET: The rank for the csv_get operations
location CSV_GET = locationFromRank(turbine_workers()-2);

(int r)
run_recursive(string csv_file, location CSV_GET, int level)
{
  string csv_lines = csv_get1(csv_file, CSV_GET);
  // printf("csv_lines: " + csv_lines);

  if (csv_lines == "EOF")
  {
    r = 0;
  }
  else
  {
    r = run_replicates(CSV_GET, level, csv_lines) +
        run_recursive (csv_file, CSV_GET, level + 1);
  }
}

(int r)
run_replicates(location CSV_GET,
               int level, string csv_lines)
{
  int A[];
  foreach seed in [0:replicates-1]
  {
    printf("agent: level=%i, seed=%i", level, seed);
    result = agent_csv_lines(level * replicates + seed, template_cfg,
                             seed, urbanpop, cases, csv_lines);
    printf("result: '%s'", result);
    result_log(result_file, result);
    A[seed] = bool2int(strlen(result) > 0);
  }
  r = sum_integer(A);
}

int N = run_recursive(csv_file, CSV_GET, 0);
printf("total runs: %i", N);
