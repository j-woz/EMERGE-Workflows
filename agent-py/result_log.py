#!/usr/bin/env python3

""" File pointer open in binary mode for NUL characters """

import atexit
import json

from datetime import datetime

BLOCK_SIZE = 64 * 1024

# Write buffer size.  Large, block-aligned writes maximize throughput
# on HPC parallel filesystems (Lustre/GPFS), where many small writes
# are slow.  Must be a multiple of BLOCK_SIZE.
WRITE_BUFFER_SIZE = 256 * BLOCK_SIZE

fp_write = None

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

    stat_parser = subparsers.add_parser("stat",
                                        help="Pretty-print the header metadata")
    stat_parser.add_argument("filename", help="Result log file")
    stat_parser.set_defaults(func=cmd_stat)

    return parser.parse_args()


def cmd_extract(args):
    for idx in args.indices:
        print("%i: %s" % (idx, extract(args.filename, idx)))


def cmd_stat(args):
    import os

    file_size = os.path.getsize(args.filename)
    file_mtime = os.path.getmtime(args.filename)
    mtime_str = datetime.fromtimestamp(file_mtime).strftime("%Y-%m-%d %H:%M:%S")

    def human_size(size):
        for unit in ('B', 'KB', 'MB', 'GB'):
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"

    print(f"File:   {args.filename}")
    print(f"Size:   {human_size(file_size)}")
    print(f"Time:   {mtime_str}")


    header = extract(args.filename, 0)
    if not header.strip():
        print("No header metadata found")
        return

    total_blocks = (file_size + BLOCK_SIZE - 1) // BLOCK_SIZE
    content_blocks = max(0, total_blocks - 1)

    print(f"Blocks: {content_blocks}")
    print()

    try:
        data = json.loads(header)
        if isinstance(data, dict):
            max_key_len = max(len(k) for k in data.keys()) if data else 0
            for key, value in data.items():
                if key == "header": continue
                print(f"  {key:<{max_key_len}}  {value}")
        else:
            print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print("Header is not valid JSON:")
        print(header)

    do_close()


def cmd_timing(args):
    entries = []
    with open(args.logfile, "rb") as fp:
        while True:
            block = pf.read(BLOCK_SIZE)
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


def write_values(filename, envs, kvs):
    """
    Format and write arbitrary data to the result.log
    Useful for workflow-level metadata
    envs: string: comma-separated list of environment variable names
    kvs:  string: comma-separated list key=value pairs
    """
    import os
    D = {}
    names = envs.split(",")
    for name in names:
        D[name] = str(os.getenv(name))
    pairs = kvs.split(",")
    for pair in pairs:
        kv = pair.split("=")
        D[kv[0]] = kv[1]
    record = json.dumps(D, indent=2) + "\n"
    result = do_write(filename, record)
    return result


def do_open_write(filename):
    global fp_write
    print("result_log: open:  '%s'" % filename, flush=True)
    fp_write = open(filename, "wb", buffering=WRITE_BUFFER_SIZE)


def do_write(filename, record):
    import time, traceback

    if len(record) > BLOCK_SIZE:
        print("result_log.do_write(): record too big: "
              "length=%i BLOCK_SIZE=%i\n" % (len(record), BLOCK_SIZE) +
              record + "\n",
              flush=True)
        time.sleep(1)
        exit(1)

    global fp_write
    try:
        if fp_write == None: do_open_write(filename)
        print("result_log: write: '%s'" % filename, flush=True)
        B = bytearray(BLOCK_SIZE)
        B[:len(record)] = record.encode("utf-8")
        fp_write.write(B)
    except Exception as e:
        print("", flush=True)
        print("result_log.do_write(): EXCEPTION: filename=" + filename)
        print("result_log.do_write(): " + str(e))
        print("", flush=True)
        t = traceback.format_exc()
        print(t)
        print("", flush=True)
        time.sleep(1)
        exit(1)

    # Return a string to Swift/T:
    return str(True)


@atexit.register
def do_close_auto():
    """
    Registered with atexit so the large write buffer is not lost
    when the workflow exits normally.
    """
    global fp_write
    if fp_write is None: return
    print("result_log: atexit: close.", flush=True)
    do_close()


def do_close():
    """
    Flush any buffered records and close the file.
    """
    global fp_write
    if fp_write is None: return
    fp_write.flush()
    fp_write.close()
    fp_write = None


def extract(filename, idx):
    """ Seek to the idx-th BLOCK_SIZE-byte block and return its string. """
    with open(filename, "rb") as fp:
        fp.seek(idx * BLOCK_SIZE)
        B = fp.read(BLOCK_SIZE)
    return B.rstrip(b"\x00").decode("utf-8")


if __name__ == "__main__":
    main()
