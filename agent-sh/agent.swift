
/**
   The params provided here override corresponding entries
   in the ExaEpi input file!
*/
app (file output, file errors) agent(file inputs)
{
  "mpiexec"
    "-bootstrap" "fork"
    "-n" "4"
    "gpu"
    "agent" inputs
    @stdout=output @stderr=errors ;
}
