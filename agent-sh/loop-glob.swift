
/**
   LOOP GLOB SWIFT
   See README
*/

import files;
import io;
import sys;

// import agent_debug;
import agent;

// The agent inputs are copied into TURBINE_OUTPUT/inputs
//     when the workflow starts
// Find all the input files:
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
  (o_file, e_file) = agent(input_file);
}
