
/**
   ONE SHOT SWIFT
   Run ExaEpi agent once
   Provide inputs file on the command line,
   e.g., /path/to/inputs.bay
*/

// Swift/T builtin libraries:
import python;
import sys;

// In ./agent.swift:
import agent;

// Just test TensorFlow:
python("import tensorflow ; print('one-shot: TensorFlow is OK')");

// Output files for the agent:
file o_file<"agent-out.txt">;
file e_file<"agent-err.txt">;

// Run the agent:
(o_file, e_file) = agent(input(argp(1)));
