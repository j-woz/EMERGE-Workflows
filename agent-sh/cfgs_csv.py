#!/usr/bin/env python3

"""
Generate cfg files from a template and CSV files.

Usage: python cfgs_csv.py [cfg_file] [output_dir] [csv_files ...]

NOTE: All strings in input are parsed as Python code!
"""

import argparse
import csv
import os
import re
import sys

VERBOSE = False

def main():
    global VERBOSE
    args = parse_args()
    VERBOSE = args.verbose
    try:
        process(
            args.cfg_file,
            args.csv_files,
            args.output_dir,
            args.no_comments,
        )
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate cfg files from a template and CSV files."
    )
    parser.add_argument(
        "cfg_file",
        help="Template cfg file (e.g. nm-input.cfg)",
    )
    parser.add_argument(
        "output_dir",
        help="Directory for output cfg files",
    )
    parser.add_argument(
        "csv_files",
        nargs='+',
        help="CSV files with parameters (order is preserved)",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Print a line for each cfg file written",
    )
    parser.add_argument(
        "-C", "--no-comments",
        action="store_true",
        help="Remove comments from output cfg files",
    )
    return parser.parse_args()

def process(cfg_path, csv_paths, output_dir, no_comments=False):
    cfg_stem = os.path.splitext(os.path.basename(cfg_path))[0]

    with open(cfg_path) as f:
        cfg_lines = f.readlines()

    os.makedirs(output_dir, exist_ok=True)

    row_id = 1
    for csv_path in csv_paths:
        with open(csv_path) as f:
            reader = csv.DictReader(f)
            for row in reader:
                stem = f"{cfg_stem}_{row_id}"
                row_keys = set(row.keys())
                output_lines = [f"id = {row_id}\n"]

                for line in cfg_lines:
                    if no_comments and line.strip().startswith("#"):
                        continue
                    m = re.match(r"^(\s*)([\w.]+)(\s*=\s*)(.*?)(\n?)$", line)
                    if m and m.group(2) == "diag.output_filename":
                        prefix, key, eq, val, nl = m.groups()
                        _, ext = os.path.splitext(val)
                        new_val = os.path.join(output_dir, stem + ext)
                        if not no_comments:
                            output_lines.append(f"# {prefix}{key}{eq}{val}\n")
                        output_lines.append(f"{prefix}{key}{eq}{new_val}\n")
                    elif m and m.group(2) in row_keys:
                        if not line.startswith("#"):
                            if not no_comments:
                                output_lines.append("# " + line)
                        else:
                            if not no_comments:
                                output_lines.append(line)
                        prefix, key, eq = m.groups()[:3]
                        value = format_value(row[key])
                        if key in ("disease.hospitalization_days_alpha", "disease.hospitalization_days_beta"):
                            value = value + " " + value
                        output_lines.append(f"{prefix}{key}{eq}{value}\n")
                    else:
                        output_lines.append(line)

                out_path = os.path.join(output_dir, stem + ".cfg")
                with open(out_path, "w") as f:
                    f.writelines(output_lines)
                verbose(f"Wrote {out_path}")

                row_id += 1

def format_value(v):
    if isinstance(v, str):
        # Assuming this is a JSON-formatted list
        # Converting to an ExaEpi-compatible space-separated list
        return v.replace(",", " ").replace("[", "").replace("]", "")
    return str(v)

def verbose(msg):
    if VERBOSE:
        print(msg)

if __name__ == "__main__":
    main()
