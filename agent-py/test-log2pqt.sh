#!/bin/zsh
set -eu

# TEST LOG2PQT SH
# Mostly for Claude

# Convert the example log to parquet in the reference format
./log2pqt results_example.log results_example.parquet

# Validate against the reference format and the source log
./validate_pqt results_example.parquet results_example.log part-000000.parquet

# Show a sample of the output
./show_pqt results_example.parquet 3

# Also test the multi-line / padded log (real newlines in strings)
./log2pqt results.log results.parquet

./validate_pqt results.parquet results.log part-000000.parquet

./show_pqt results.parquet 3
