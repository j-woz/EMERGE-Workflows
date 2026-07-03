
import python;

/** Swift/T interfaces for Python layer call to ExaEpi agent */

/** params should be string of Python dict */
(string result)
agent_dict(int idx, string input_cfg, int seed,
           string urbanpop, string cases,
           string params)
{
  result =
    python_persist
    ("import exaepi_agent",
     "exaepi_agent.run_str_dict(%i, '%s', %i, '%s', '%s', '%s')" %
     (idx, input_cfg, seed, urbanpop, cases, params));
}

/** params should be string of Python dict */
(string result)
agent_csv_lines(int idx, string input_cfg, int seed,
                string urbanpop, string cases,
                string csv_lines)
{
  // Need triple-quote - csv_lines contains NL
  result =
    python_persist
    ("""
import traceback
import exaepi_agent
try:
    result = exaepi_agent.run_csv_lines(%i, \"%s\", %i, \"%s\", \"%s\", '''%s''')
except Exception as e:
    print('exaepi_agent.run_csv_lines(): Exception: ' + str(e))
    print('', flush=True)
    t = traceback.format_exc()
    print(t)
    print('', flush=True)
    exit(1)
""" %
     (idx, input_cfg, seed, urbanpop, cases, csv_lines),
     "str(result)");
}
