
/**
   LOOP GLOB SWIFT
   See README
*/

import files;
import io;
import string;
import sys;

// import agent_debug;
import agent;

// The agent inputs are copied into TURBINE_OUTPUT/inputs
//     when the workflow starts
// Find all the input files:
file inputs[] = glob("inputs/*.bay");
printf("loop-glob: found inputs: " + size(inputs));

foreach ifile, i in inputs
{
  // Example: "input_8_v2_157.bay" -> "input_8_v2_157"
  name = rootname(ifile);
  // Example: "input_8_v2_157" -> "157"
  // string tokens[] = split(name, "_");
  // index = string2int(tokens[size(tokens)-1]);
  output = name + ".stdout";
  errors = name + ".stderr";
  printf("loop-glob: running ExaEpi input %s", filename(ifile));
  file o_file<output>;
  file e_file<errors>;
  (o_file, e_file) = agent(ifile);
}
