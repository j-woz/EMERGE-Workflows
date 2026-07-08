
# HOOK TCL
# This code runs on each leader rank,
#      i.e., once per node.

# Set a root data directory
set root $env(HOME)/data
puts "HOOK HOST: [exec hostname]"

# Get the leader communicator from ADLB
set comm [ adlb::comm_get leaders ]
# Get my rank among the leaders
set rank [ adlb::comm_rank $comm ]

# If I am rank=0, construct the list of files to copy
set DATA_DIR $env(HOME)/proj/EMERGE-WF/data-sets
set file_tmplt $env(TEMPLATE_CFG)
set file_cases $DATA_DIR/NM_Mar16.cases
set file_pop   $DATA_DIR/urbanpop_nm.bin
set file_agent $DATA_DIR/agent

if { $rank == 0 } {
  set files [ list $file_tmplt $file_cases $file_pop $file_agent ]
  puts "files: $files"
}

# Broadcast the file list to all leaders
turbine::c::bcast $comm 0 files

# Make a node-local data directory
set LOCAL_PREFIX /tmp/$env(USER)/exaepi
file mkdir $LOCAL_PREFIX

# Copy each file to the node-local directory
foreach f $files {
  if { $rank == 0 } {
    puts "copying: $f"
  }
  turbine::c::copy_to $comm $f $LOCAL_PREFIX
}
