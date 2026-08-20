
"""
SCRAPER TEMPLATE

Rename this and edit it for various data scraping use cases.

To be called by the workflow system as:

```python
agent_out  = f"{run_dir}/agent.out"   # ExaEpi stdout
agent_dat  = f"{run_dir}/output.dat"  # ExaEpi product
agent_plts = f"{run_dir}/pltdir"      # ExaEpi PLT dir

import scraper_template
# D2: dict of additional output parameters
D2 = scraper_template.scrape(agent_out, agent_dat, agent_plts)
```

D2 should be a Python dict that is easily merged with another Python dict
and converted to JSON for streaming to a result log file.

See exaepi_agent.py get_results()
for how we currently scrape the logs.
"""

def scrape(agent_out, agent_dat, agent_plts):
    """ Default template implementation: Do nothing! """

    # Could open given files, parse, update result:
    result = {}
    return result
