
/**
   The params provided here override corresponding entries
   in the ExaEpi input file!
*/
app (file output, file errors) agent(file inputs)
{
  // "which" "agent" "mpiexec"

  // Aurora:
  "mpiexec"   "-n" "1" "-launcher" "fork"
   "env"
    "-u" "PMIX_NAMESPACE"
    "PMIX_MCA_psec=none"

    "agent" inputs "agent.fast=1"
    @stdout=output @stderr=errors
    ;
}
