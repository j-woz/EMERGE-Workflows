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


def process_parse(template_cfg, rundir, seed, urbanpop, cases, params, input_cfg):
    """
    template_cfg: original cfg on disk
    rundir:       directory in which ExaEpi should run and write data
    seed:         int seed
    params:       dict of other parameters to modify (in string form)
    input_cfg:    ExaEpi input file generated here.
    returns:      The id number from the cfg
    """

    P = eval(params)
    return process(template_cfg, rundir, seed, urbanpop, cases, P,
                   input_cfg)


def process(template_cfg, rundir, seed, urbanpop, cases, params, input_cfg):
    """
    Edits the template_cfg creating the input_cfg for ExaEpi
    Always edits: seed, file locations
    Also edits:   anything in the given params

    template_cfg: original cfg on disk
    rundir:       directory in which ExaEpi should run and write data
    seed:         int seed
    params:       dict of other parameters to modify
    input_cfg:    ExaEpi input file generated here.
    returns:      The id number from the cfg
    """

    # Keys targeted for editing:
    key_targets = params.keys()

    with open(template_cfg) as f:
        template_lines = f.readlines()

    # Contents to write to input_cfg:
    output_lines = []
    # Keep track of what we have edited so far:
    applied_keys = set()

    result_id = None

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
        if key == "id":
            result_id = val
        elif key == "agent.seed":
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
        elif key in key_targets:
            verbose("edit target: " + key)
            output_lines.append("# " + line if line.endswith("\n")
                                else "# " + line + "\n")
            new_val = params[key]
            if key in ("disease.hospitalization_days_alpha",
                       "disease.hospitalization_days_beta"):
                verbose("  and double")
                # Duplicate these lists
                new_val = eval(new_val)
                new_val += new_val

            new_val = format_value(new_val)

            output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
            applied_keys.add(key)
        else:
            output_lines.append(line)

    # Append any params that were not present in the template:
    for key in key_targets:
        if key not in applied_keys:
            output_lines.append(f"{key} = {format_value(params[key])}\n")

    # Write the new ExaEpi input file!
    with open(input_cfg, "w") as f:
        f.writelines(output_lines)
    verbose(f"cfg_edit: wrote {input_cfg}")

    return result_id


csv_id = 0
csv_fp = None
csv_fields = None


def csv_open(filename):
    """ Open CSV and load field names from header """
    global csv_fp, csv_fields
    csv_fp = open(filename, 'r')
    csv_fields = csv_fp.readline().strip()


def csv_get(filename):
    """ Return next row from CSV """
    global csv_fp, csv_fields
    if csv_fp is None: csv_open(filename)
    line = csv_fp.readline()
    if len(line) == 0: return "EOF"
    line = line.strip()
    result = csv_fields + '\n' + line
    return result


def format_value(v):
    """ Format any lists for ExaEpi cfg file syntax """
    if isinstance(v, list):
        return " ".join(str(x) for x in v)
    return str(v)


def verbose(msg):
    if VERBOSE:
        print(msg)


if __name__ == "__main__":
    main()
