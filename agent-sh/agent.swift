
/**
   The params provided here override corresponding entries
   in the ExaEpi input file!
*/
app (file output, file errors) agent(file inputs)
{
  "mpiexec"   "-n" "2"
  "env"
    "-u" "PMIX_NAMESPACE" last
    // "PMIX_MCA_psec=none"
    "agent" inputs "agent.fast=1"
    @stdout=output @stderr=errors
    ;
}
