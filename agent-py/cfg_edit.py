#!/usr/bin/env python3

"""
Generate a cfg file from a template

Usage: python cfg_json.py [cfg_file] [ude_file] [output_dir]
"""

import argparse
import json
import os
import re
import sys

SKIP_KEYS = {"instance", "replicates"}

VERBOSE = False

def process(template_cfg, rundir, seed, params, input_cfg):
    """
    template_cfg: original cfg on disk
    rundir:       directory in which ExaEpi should run and write data
    seed:         int seed
    params:       dict of other parameters to modify
    input_cfg:    ExaEpi input file generated here.
    """

    K = params.keys()

    with open(template_cfg) as f:
        template_lines = f.readlines()

    for line in template_lines:
        if line.startswith("#"):
            output_lines.append(line)
        m = re.match(r"^(\s*)([\w.]+)(\s*=\s*)(.*?)(\n?)$", line)
        if m is None: continue
        key = m.group(2)
        if key == "diag.output_filename":
            prefix, key, eq, val, nl = m.groups()
            _, ext = os.path.splitext(val)
            new_val = output_dir, stem + ext)
            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
        elif key in K:
            output_lines.append("# " + line)
            commented_keys.append(m.group(2))
        else:
            output_lines.append(line)


    with open(input_cfg, "w") as f:
        f.writelines(output_lines)
    verbose(f"Wrote {out_path}")

def format_value(v):
    if isinstance(v, list):
        return " ".join(str(x) for x in v)
    return str(v)

def verbose(msg):
    if VERBOSE:
        print(msg)

if __name__ == "__main__":
    main()
