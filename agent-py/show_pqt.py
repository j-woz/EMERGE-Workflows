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
    if len(sys.argv) < 2:
        print("Usage: python3 show_pqt.py <file.parquet> [max_rows]")
        sys.exit(2)

    path = sys.argv[1]
    max_rows = int(sys.argv[2]) if len(sys.argv) > 2 else None

    try:
        import pyarrow.parquet as pq
    except ImportError:
        print("pyarrow not installed. Run: pip install pyarrow")
        sys.exit(1)

    table = pq.read_table(path)

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
