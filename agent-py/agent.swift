
import python;

(string result)
agent(int idx, string input_cfg, int seed, string params)
{
  result =
    python_persist("import exaepi_agent",
                   "exaepi_agent.run(%i, '%s', %i, '%s')" %
                   (idx, input_cfg, seed, params));
}
