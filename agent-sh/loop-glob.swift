
import files;
import io;
import sys;

import agent_debug;

string directory = argp(1);

printf("loop-glob: directory: " + directory);

file inputs[] = glob(directory / "*.bay");

printf("loop-glob: found inputs: " + size(inputs));

foreach input_file, i in inputs
{
  output = "output-%i.txt" % i;
  errors = "errors-%i.txt" % i;
  printf("loop-glob: running ExaEpi input[%i]: %s",
         i, filename(input_file));
  file o_file<output>;
  file e_file<errors>;
  (o_file, e_file) = agent(input_file);
}
