
/**
   The params provided here override corresponding entries
   in the ExaEpi input file!
*/
app (file output, file errors) agent(file inputs)
{
  // "which" "mpiexec" "agent"
  //   "-bootstrap" "fork"
  //   "-n" "4"
  //   "gpu"
  // "pe.zsh" @stdout=output ;
  "env"
    // "-u" "LD_LIBRARY_PATH"
    "-u" "ENVIRONMENT"
    "-u" "MPI_HOME"
    "-u" "PALS_SPOOL_DIR"
    "-u" "PBS_JOBCOOKIE"
    "-u" "PBS_NODEFILE"
    "agent" inputs "agent.fast=1"
    // @stdout=output @stderr=errors
    ;
}
