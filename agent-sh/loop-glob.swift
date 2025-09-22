
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
  // Example: "input_8_v2_157.bay" -> "input_8_v2_157"
  name = rootname_string(input_file);
  // Example: "input_8_v2_157" -> "157"
  string tokens[] = split(name, "_");
  index = string2int(tokens[size(tokens)-1]);
  output = "output/output-%04i.txt" % index;
  errors = "output/errors-%04i.txt" % index;
  printf("loop-glob: running ExaEpi input[%04i]: %s",
         index, filename(input_file));
  file o_file<output>;
  file e_file<errors>;
  (o_file, e_file) = agent(input_file);
}
