#!/usr/bin/env python3

""" File pointer open in binary mode for NUL characters """

BLOCK_SIZE = 4 * 1024

fp = None

def main():
    filename, indices = parse_args()
    for idx in indices:
        print("%i: %s" % (idx, extract(filename, idx)))


def parse_args():
    import sys
    if len(sys.argv) < 3:
        print("usage: result_log.py <filename> [idx ...]")
        sys.exit(1)
    filename = sys.argv[1]
    indices = [int(a) for a in sys.argv[2:]]
    return filename, indices


def do_open_write(filename):
    global fp
    print("result_log: open:  '%s'" % filename, flush=True)
    fp = open(filename, "wb")


def do_open_read(filename):
    global fp
    print("result_log: open:  '%s'" % filename, flush=True)
    fp = open(filename, "rb")


def do_write(filename, record):
    global fp
    if fp == None: do_open_write(filename)
    print("result_log: write: '%s'" % filename, flush=True)
    B = bytearray(BLOCK_SIZE)
    B[:len(record)] = record.encode("utf-8")
    fp.write(B)
    fp.flush()
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
