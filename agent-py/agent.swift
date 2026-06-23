
import python;

/** Swift/T interface for Python layer call to ExaEpi agent */
(string result)
agent(int idx, string input_cfg, int seed, string urbanpop, string cases,
      string params)
{
  result =
    python_persist("import exaepi_agent",
                   "exaepi_agent.run(%i, '%s', %i, '%s', '%s', '%s')" %
                   (idx, input_cfg, seed, urbanpop, cases, params));
}
