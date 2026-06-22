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


def main():
    global VERBOSE
    args = parse_args()
    VERBOSE = args.verbose
    params = {}
    for item in args.param:
        if "=" not in item:
            raise ValueError(f"param must be key=value: {item}")
        key, val = item.split("=", 1)
        params[key] = val
    process(args.template_cfg, args.rundir, args.seed, params,
            args.input_cfg)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate a cfg file from a template")
    parser.add_argument("template_cfg",
                        help="original cfg on disk")
    parser.add_argument("input_cfg",
                        help="ExaEpi input file to generate")
    parser.add_argument("rundir",
                        help="directory in which ExaEpi should run")
    parser.add_argument("-s", "--seed", type=int, default=0,
                        help="int seed")
    parser.add_argument("-p", "--param", action="append", default=[],
                        metavar="KEY=VALUE",
                        help="parameter to modify (repeatable)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="enable verbose output")
    return parser.parse_args()


def process(template_cfg, rundir, seed, urbanpop, cases, params, input_cfg):
    """
    template_cfg: original cfg on disk
    rundir:       directory in which ExaEpi should run and write data
    seed:         int seed
    params:       dict of other parameters to modify (in string form)
    input_cfg:    ExaEpi input file generated here.
    """

    P = eval(params)
    K = P.keys()

    with open(template_cfg) as f:
        template_lines = f.readlines()

    output_lines = []
    applied_keys = set()

    for line in template_lines:
        if line.startswith(" "):
            line = line.lstrip()
        if line.startswith("#"):
            output_lines.append(line)
            continue
        m = re.match(r"^(\s*)([\w.]+)(\s*=\s*)(.*?)(\n?)$", line)
        if m is None:
            output_lines.append(line)
            continue
        prefix, key, eq, val, nl = m.groups()
        if key == "agent.seed":
            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
            output_lines.append(f"{prefix}{key}{eq}{seed}\n")
        elif key == "agent.urbanpop_filename":
            new_val = os.path.join(rundir, urbanpop)
            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
        elif key == "disease.case_filename":
            new_val = os.path.join(rundir, cases)
            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
        elif key == "diag.output_filename":
            _, ext = os.path.splitext(val)
            new_val = os.path.join(rundir, os.path.basename(val))
            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
        elif key in K:
            output_lines.append("# " + line if line.endswith("\n")
                                else "# " + line + "\n")
            new_val = format_value(params[key])
            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
            applied_keys.add(key)
        else:
            output_lines.append(line)

    # Append any params that were not present in the template.
    for key in K:
        if key not in applied_keys:
            output_lines.append(f"{key} = {format_value(params[key])}\n")

    with open(input_cfg, "w") as f:
        f.writelines(output_lines)
    verbose(f"cfg_edit: wrote {input_cfg}")


def format_value(v):
    if isinstance(v, list):
        return " ".join(str(x) for x in v)
    return str(v)


def verbose(msg):
    if VERBOSE:
        print(msg)


if __name__ == "__main__":
    main()
