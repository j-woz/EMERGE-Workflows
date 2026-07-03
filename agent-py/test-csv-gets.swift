
/**
   TEST CSV GETS
*/

import io;
import location;
import python;
import sys;

import csv_get;

string csv_file = argp(1);

printf("csv_file: " + csv_file);

// CSV_GET: The rank for the csv_get operations
location CSV_GET = locationFromRank(turbine_workers()-1);

(int r)
run_recursive(string csv_file, location CSV_GET)
{
  string csv_lines = csv_get1(csv_file, CSV_GET);
  printf("csv_lines: " + csv_lines);
  if (csv_lines == "EOF")
  {
    r = 0;
  }
  else
  {
    r = run_recursive(csv_file, CSV_GET) + 1;
  }
}

result = run_recursive(csv_file, CSV_GET);
printf("result: %i", result);
