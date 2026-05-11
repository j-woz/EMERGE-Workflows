#!/usr/bin/env python3

"""
Scan a run directory and report early-exit counts and SETUP/SIM timings.
"""

import argparse
import glob
import os
import re
import statistics
import sys

SETUP_RE = re.compile(r"^TIME:\s*SETUP:\s*([0-9.]+)")
SIM_RE = re.compile(r"^TIME:\s*SIM:\s*([0-9.]+)")


def main():
    args = parse_args()

    if not os.path.isdir(args.rundir):
        sys.exit(f"not a directory: {args.rundir}")

    stdouts = sorted(glob.glob(os.path.join(args.rundir, "seed_*.stdout")))
    if not stdouts:
        sys.exit(f"no seed_*.stdout files in {args.rundir}")

    setup_times, sim_times, total_times, early = [], [], [], []

    for p in stdouts:
        setup, sim, is_early = scan_stdout(p)
        if is_early:
            early.append(p)
            continue
        if setup is not None:
            setup_times.append(setup)
        if sim is not None:
            sim_times.append(sim)
        if setup is not None and sim is not None:
            total_times.append(setup + sim)

    total = len(stdouts)

    print(f"Run directory: {args.rundir}")
    print(f"Total seed runs: {total}")
    print(f"Early exits: {len(early)}")
    print("Timings (seconds):")
    summarize("SETUP", setup_times)
    summarize("SIM  ", sim_times)
    summarize("TOTAL", total_times)

    if args.verbose and early:
        print("Early-exit files:")
        for p in early:
            print(f"  {os.path.basename(p)}")


def parse_args():
    ap = argparse.ArgumentParser(description=
             "Show timing results for run directory")
    ap.add_argument("rundir", help="Path to a run_* directory")
    ap.add_argument("-v", "--verbose", action="store_true")
    return ap.parse_args()


def scan_stdout(path):
    setup = sim = None
    early = False
    with open(path, "r", errors="replace") as f:
        for line in f:
            if "EARLY-EXIT" in line:
                early = True
            m = SETUP_RE.match(line)
            if m:
                setup = float(m.group(1))
                continue
            m = SIM_RE.match(line)
            if m:
                sim = float(m.group(1))
    return setup, sim, early


def summarize(name, values):
    if not values:
        print(f"  {name}: (none)")
        return
    print(f"  {name:<6} "
          f"n={len(values):>4}  "
          f"min={min(values):>8.2f}  "
          f"max={max(values):>8.2f}  "
          f"mean={statistics.mean(values):>8.2f}  "
          f"median={statistics.median(values):>8.2f}  "
          f"total={sum(values):>10.2f}")


if __name__ == "__main__":
    main()
