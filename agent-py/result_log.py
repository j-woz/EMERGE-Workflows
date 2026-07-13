#!/usr/bin/env python3

""" File pointer open in binary mode for NUL characters """

import json

from datetime import datetime

BLOCK_SIZE = 4 * 1024

fp = None

def main():
    args = parse_args()
    args.func(args)


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(description="Result log utilities")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    subparsers.required = True

    extract_parser = subparsers.add_parser("extract",
                                           help="Extract records by index")
    extract_parser.add_argument("filename", help="Result log file")
    extract_parser.add_argument("indices", nargs="+", type=int,
                                help="Record indices to extract")
    extract_parser.set_defaults(func=cmd_extract)

    timing_parser = subparsers.add_parser("timing",
                                          help="Analyze timing statistics")
    timing_parser.add_argument("logfile", help="Results log file to analyze")
    timing_parser.set_defaults(func=cmd_timing)

    return parser.parse_args()


def cmd_extract(args):
    for idx in args.indices:
        print("%i: %s" % (idx, extract(args.filename, idx)))


def cmd_timing(args):
    entries = []
    with open(args.logfile, "rb") as f:
        while True:
            block = f.read(BLOCK_SIZE)
            if not block:
                break
            entry_str = block.rstrip(b"\x00").decode("utf-8").strip()
            if not entry_str:
                continue
            try:
                entry = json.loads(entry_str)
                if isinstance(entry, dict) and "start" in entry and "stop" in entry:
                    entries.append(entry)
            except json.JSONDecodeError:
                pass

    if not entries:
        print("No timing events found in log file")
        return

    durations = []
    for entry in entries:
        start = float(entry["start"])
        stop = float(entry["stop"])
        duration = stop - start
        durations.append(duration)
        print(f"Index {len(durations)-1}: {duration:.3f}s")

    if durations:
        print(f"\nTiming Statistics:")
        print(f"  Count:   {len(durations)}")
        print(f"  Min:     {min(durations):.3f}s")
        print(f"  Max:     {max(durations):.3f}s")
        print(f"  Average: {sum(durations) / len(durations):.3f}s")
        print(f"  Total:   {sum(durations):.3f}s")


def do_open_write(filename):
    global fp
    # print("result_log: open:  '%s'" % filename, flush=True)
    fp = open(filename, "wb")


def do_open_read(filename):
    global fp
    # print("result_log: open:  '%s'" % filename, flush=True)
    fp = open(filename, "rb")


def do_write(filename, record):
    import time, traceback

    global fp
    try:
        if fp == None: do_open_write(filename)
        # print("result_log: write: '%s'" % filename, flush=True)
        B = bytearray(BLOCK_SIZE)
        B[:len(record)] = record.encode("utf-8")
        fp.write(B)
        fp.flush()
    except Exception as e:
        print("", flush=True)
        print("result_log.do_write(): EXCEPTION: filename=" + filename)
        print("result_log.do_write() " + str(e))
        print("", flush=True)
        t = traceback.format_exc()
        print(t)
        print("", flush=True)
        time.sleep(1)
        exit(1)

    # Return a string to Swift/T:
    return str(True)


def extract(filename, idx):
    """ Seek to the idx-th BLOCK_SIZE-byte block and return its string. """
    with open(filename, "rb") as f:
        f.seek(idx * BLOCK_SIZE)
        B = f.read(BLOCK_SIZE)
    return B.rstrip(b"\x00").decode("utf-8")


if __name__ == "__main__":
    main()
