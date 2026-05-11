#!/usr/bin/env python3

"""
Generate cfg files from a template and a JSON UPF.

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
    try:
        process(
            args.cfg_file,
            args.upf_file,
            args.output_dir,
        )
    except KeyError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate cfg files from a template and a JSON UPF."
    )
    parser.add_argument(
        "cfg_file",
        help="Template cfg file (e.g. nm-input.cfg)",
    )
    parser.add_argument(
        "upf_file",
        help="UPF file with one JSON fragment per line",
    )
    parser.add_argument(
        "output_dir",
        help="Directory for output cfg files and diag.output_filename",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Print a line for each cfg file written",
    )
    return parser.parse_args()

def process(cfg_path, ude_path, output_dir):

    # fragments: List of JSON data from UDE
    #            Each fragment is a dict specifying 1 simulation 
    # output_lines: List of lines in new cfg file

    cfg_stem = os.path.splitext(os.path.basename(cfg_path))[0]

    with open(cfg_path) as f:
        cfg_lines = f.readlines()

    with open(ude_path) as f:
        fragments = [json.loads(line) for line in f if line.strip()]

    os.makedirs(output_dir, exist_ok=True)

    for i, fragment in enumerate(fragments):
        if "instance" not in fragment:
            raise KeyError(
                f"fragment {i} is missing required key 'instance'"
            )
        instance = fragment["instance"]
        fragment["agent.seed"] = instance
        stem = f"{cfg_stem}_{instance}"
        frag_keys = {k for k in fragment if k not in SKIP_KEYS}
        commented_keys = []
        output_lines = [f"instance = {instance}\n"]

        for line in cfg_lines:
            m = re.match(r"^(\s*)([\w.]+)(\s*=\s*)(.*?)(\n?)$", line)
            if m and m.group(2) == "diag.output_filename":
                prefix, key, eq, val, nl = m.groups()
                _, ext = os.path.splitext(val)
                new_val = os.path.join(output_dir, stem + ext)
                output_lines.append(f"# {prefix}{key}{eq}{val}\n")
                output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
            elif m and m.group(2) in frag_keys:
                if line.startswith("#"):
                    output_lines.append(line)
                else:
                    output_lines.append("# " + line)
                commented_keys.append(m.group(2))
            else:
                output_lines.append(line)

        if commented_keys:
            if output_lines and output_lines[-1].strip():
                output_lines.append("\n")
            for k in commented_keys:
                val = fragment[k]
                if k in ("disease.hospitalization_days_alpha",
                         "disease.hospitalization_days_beta"):
                    val = list(val) + list(val)
                v = format_value(val)
                output_lines.append(f"{k} = {v}\n")

        out_path = os.path.join(output_dir, stem + ".cfg")
        with open(out_path, "w") as f:
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
