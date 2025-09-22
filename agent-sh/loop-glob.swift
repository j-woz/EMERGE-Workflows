
/**
   LOOP GLOB SWIFT
   See README
*/

import files;
import io;
import sys;

// import agent_debug;
import agent;

string dir_data   = argp(1);

// Construct command-line parameters for the agent
printf("loop-glob: dir_data: " + dir_data);
string params[] = [
  "agent.census_filename="     + dir_data / "CensusData" / "BayArea.dat",
  "agent.workerflow_filename=" + dir_data / "CensusData" / "BayArea-wf.bin",
  "disease.case_filename="     + dir_data / "CaseData"   / "Feb1.cases"
];

// Find all the input files:
// printf("loop-glob: dir_inputs: " + realpath_string("inputs"));
file inputs[] = glob("inputs/*.bay");
printf("loop-glob: found inputs: " + size(inputs));

foreach input_file, i in inputs
{
  output = "output/output-%4i.txt" % i;
  errors = "output/errors-%4i.txt" % i;
  printf("loop-glob: running ExaEpi input[%4i]: %s",
         i, filename(input_file));
  file o_file<output>;
  file e_file<errors>;
  (o_file, e_file) = agent(input_file, params);
}
