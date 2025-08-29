
app (file output, file errors) agent(file inputs)
{
  "mpiexec"
    "-bootstrap" "fork"
    "-n" "4"
    "gpu"
    "agent" inputs
    @stdout=output @stderr=errors ;
}
