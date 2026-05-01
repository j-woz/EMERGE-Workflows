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

def verbose(msg):
    if VERBOSE:
        print(msg)

def format_value(v):
    if isinstance(v, list):
        return " ".join(str(x) for x in v)
    return str(v)

def process(cfg_path, ude_path, output_dir="."):
    with open(cfg_path) as f:
        cfg_lines = f.readlines()

    with open(ude_path) as f:
        fragments = [json.loads(line) for line in f if line.strip()]

    os.makedirs(output_dir, exist_ok=True)

    for i, fragment in enumerate(fragments):
        instance = fragment.get("instance", i + 1)
        frag_keys = {k for k in fragment if k not in SKIP_KEYS}
        commented_keys = []
        output_lines = []

        for line in cfg_lines:
            m = re.match(r"^(\s*)([\w.]+)(\s*=\s*)(.*)(\n?)$", line)
            if m and m.group(2) in frag_keys:
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
                v = format_value(fragment[k])
                output_lines.append(f"{k} = {v}\n")

        fname = f"input_{instance}.cfg"
        out_path = os.path.join(output_dir, fname)
        with open(out_path, "w") as f:
            f.writelines(output_lines)
        verbose(f"Wrote {out_path}")

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
        help="Directory where output cfg files are written",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Print a line for each cfg file written",
    )
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    VERBOSE = args.verbose
    process(args.cfg_file, args.upf_file, args.output_dir)
