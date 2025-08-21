
/**
   ONE SHOT SWIFT
   Run ExaEpi agent once
   Provide inputs file on the command line,
   e.g., /path/to/inputs.bay
*/

import sys;

app agent(file inputs)
{
  // "gpu" is the shell wrapper in 
  "mpiexec" "-n" "4" "gpu" "agent" inputs ;
}

agent(input(argp(1)));
