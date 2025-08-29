
import io;
import sys;

import agent;

foreach i in [1:argc()]
{
  output = "output-%i.txt" % i;
  errors = "errors-%i.txt" % i;
  printf("running ExaEpi inputs: %s => %s", argp(i), output);
  file o_file<output>;
  file e_file<errors>;
  (o_file, e_file) = agent(input(argp(i)));
}
