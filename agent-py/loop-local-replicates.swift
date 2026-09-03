
/**
   LOOP LOCAL REPLICATES SWIFT
   See README
   See Command Line Arguments below for usage
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

arguments(string params_csv   : "CSV of parameters to run",
          int    replicates   : "Number of iterations per CSV line",
          string result_file  : "Final output result log");

input_dir = getenv("INPUT_DIR");
template_cfg = input_dir / "template.cfg";
pop_bin      = input_dir / "pop.bin";
cases_data   = input_dir / "cases.data";

assert(turbine_workers() >= 3, "need at least 3 workers!");

// RL: The location for the Result Log:
location RL = locationFromRank(turbine_workers()-1);

(void v)
result_log_vars(string filename, string envs, string kvs)
{
  // Writes a arbitrary data to the log
  t =
  @location=RL
    python_persist("import result_log",
                   "result_log.write_values(\"%s\", \"%s\", \"%s\")" %
                   (filename, envs, kvs));
  v = propagate(t);
}

result_log_write(string filename, string record)
{
  // Writes a simulation record to the log
  // Need triple-quote: record strings contain NLs
  if (find(getenv("OPTZ_IO"), "O", 0, -1) >= 0 ) {
    @location=RL
      python_persist("import result_log",
                     "result_log.do_write(\"%s\", \"\"\"%s\"\"\")" %
                     (filename, record));
  }
}

printf("params_csv: " + params_csv);

// CSV_GET: The rank for the csv_get operations
location CSV_GET = locationFromRank(turbine_workers()-2);

(int r)
run_recursive(string template_cfg, string pop_bin, string cases_data,
              string params_csv, location CSV_GET, int level)
{
  string csv_lines = csv_get1(params_csv, CSV_GET);
  // printf("csv_lines: " + csv_lines);

  if (csv_lines == "EOF")
  {
    r = 0;
  }
  else
  {
    r = run_replicates(template_cfg, pop_bin, cases_data,
                       CSV_GET, level, csv_lines) +
        run_recursive (template_cfg, pop_bin, cases_data,
                       params_csv, CSV_GET, level + 1);
  }
}

(int r)
run_replicates(string template_cfg, string pop_bin, string cases_data,
               location CSV_GET, int level, string csv_lines)
{
  int A[];
  foreach seed in [0:replicates-1]
  {
    // printf("agent: level=%i, seed=%i", level, seed);
    task_id = level * replicates + seed;
    result = agent_csv_lines(task_id, template_cfg,
                             pop_bin, cases_data, seed, csv_lines);
    // printf("result: '%s'", result);
    result_log_write(result_file, result);
    A[seed] = bool2int(strlen(result) > 0);
  }
  r = sum_integer(A);
}

// Specify some metadata for the result.log header:
envs = "USER,PROCS,PPN,PWD";
hostname, code1 = system1("hostname");
domain,   code2 = system1("hostname -d");
site = hostname + "." + domain;
time_string = clock_format(CLOCK_FMT_RFC3339, clock());
ee_install = agent_installation();
ee_version = agent_version();
kv_array = [
               "header=true",
               "date="           + time_string,
               "template="       + realpath_string(template_cfg),
               "params_csv="     + realpath_string(params_csv),
               "urbanpop="       + realpath_string(pop_bin),
               "cases="          + realpath_string(cases_data),
               "replicates=%i"   % replicates,
               "site="           + site,
               "exaepi_install=" + ee_install,
               "exaepi_version=" + ee_version
             ];
kvs = join(kv_array, ",");

// Write the result.log header:
result_log_vars(result_file, envs, kvs) =>
// Kick off the workflow:
int N = run_recursive(template_cfg, pop_bin, cases_data,
                      params_csv, CSV_GET, 0);
// Report a final count:
printf("total runs: %i", N);
