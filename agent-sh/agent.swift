
app (file output, file errors) agent(file inputs, string params[])
{
  "mpiexec"
    "-bootstrap" "fork"
    "-n" "4"
    "gpu"
    "agent" inputs params
    @stdout=output @stderr=errors ;
}
