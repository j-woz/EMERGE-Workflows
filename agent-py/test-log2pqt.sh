#!/bin/zsh
set -eu

# TEST LOG2PQT SH
# Mostly for Claude

# Convert the log to parquet in the reference format
./log2pqt results.log results.parquet

# Validate against the reference format and the source log
./validate_pqt results.parquet results.log part-000000.parquet

# Show a sample of the output
./show_pqt results.parquet 3
