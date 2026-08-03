#!/usr/bin/env python3
"""
Display the contents of a Parquet file.

Usage:
    python3 show_pqt.py <file.parquet> [max_rows]

Prints the schema, row count, and each record's fields. Long string values
(e.g. the output_dat table) are truncated for readability.
"""

import sys

TRUNC = 80  # max chars to show per value


def main():
    args = parse_args()
    check_installation()
    show(args.file, args.max_rows)


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        description="Display the contents of a Parquet file.")
    parser.add_argument("file", help="Parquet file to display")
    parser.add_argument("max_rows", nargs="?", type=int, default=None,
                        help="maximum number of rows to show")
    return parser.parse_args()


def check_installation():
    global pq
    try:
        import pyarrow.parquet as pq
    except ImportError:
        print("pyarrow not installed. Run: pip install pyarrow")
        sys.exit(1)


def show(filename, max_rows=None):
    table = pq.read_table(filename)

    # Show file metadata if present
    if table.schema.metadata:
        print("File Metadata:")
        for key, value in sorted(table.schema.metadata.items()):
            if isinstance(key, bytes):
                key = key.decode('utf-8')
            if isinstance(value, bytes):
                value = value.decode('utf-8')
            print(f"  {key}: {value}")
        print()

    print("Schema:")
    print(table.schema)
    print()
    print(f"Rows: {table.num_rows}   Columns: {table.num_columns}")
    print()

    rows = table.to_pylist()
    if max_rows is not None:
        rows = rows[:max_rows]

    for i, row in enumerate(rows):
        print(f"--- Record {i} ---")
        for k, v in row.items():
            s = str(v)
            if len(s) > TRUNC:
                s = s[:TRUNC] + f"... ({len(str(v))} chars)"
            print(f"  {k}: {s}")
        print()

    if max_rows is not None and table.num_rows > max_rows:
        print(f"({table.num_rows - max_rows} more rows not shown)")


if __name__ == "__main__":
    main()
