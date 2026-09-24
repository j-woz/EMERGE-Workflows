
# STAGE DATA
# To be sourced by workflow shell script
# Assumes all these variables have been set

mkdir -pv $TURBINE_OUTPUT
cp -uv $TEMPLATE_ORIGIN $TEMPLATE_CFG
cp -uv $POP_BIN_ORIGIN  $POP_BIN
cp -uv $CASES_ORIGIN    $CASES_DATA
cp -uv $AGENT_ORIGIN $THIS/affinity.sh $TURBINE_OUTPUT
bak $TURBINE_OUTPUT/data-origins.txt
{
  # Record original data locations for provenance
  msg "DATA ORIGINS"
  show AGENT_ORIGIN TEMPLATE_ORIGIN POP_BIN_ORIGIN CASES_ORIGIN \
       OPTZ_IO
} > $TURBINE_OUTPUT/data-origins.txt
