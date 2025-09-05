
/*
  AGENT DEBUG
  Like agent.swift,
  but just prints its arguments into the output file
*/

app (file output, file errors) agent(file inputs)
{
  "/bin/echo"
    "mpiexec"
    "-bootstrap" "fork"
    "-n" "4"
    "gpu"
    "agent" inputs
    @stdout=output @stderr=errors ;
}
