#!/usr/bin/env python3
"""
Display the contents of a Parquet file.

Usage:
    python3 show_pqt.py <file.parquet> [max_rows]
    python3 show_pqt.py <file.parquet> --only-ids

Prints the file metadata, schema, row count, and each record's fields. Long
string values (e.g. the output_dat table) are truncated for readability.

Only max_rows records are read off disk, so this stays cheap on large files.

With --only-ids, prints the distinct row_id values and their row counts in
place of the records, and reports whether any row_id was written more than
once.
"""

import sys

TRUNC = 80  # max chars to show per value


def main():
    args = parse_args()
    check_installation()
    show(args.file, args.max_rows, args.only_ids)


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        description="Display the contents of a Parquet file.")
    parser.add_argument("file", help="Parquet file to display")
    parser.add_argument("max_rows", nargs="?", type=int, default=None,
                        help="maximum number of rows to show")
    parser.add_argument("--only-ids", action="store_true",
                        help="show distinct row_id values and their "
                             "row counts instead of the records")
    return parser.parse_args()


def check_installation():
    global pq
    try:
        import pyarrow.parquet as pq
    except ImportError:
        print("pyarrow not installed. Run: pip install pyarrow")
        sys.exit(1)


def show(filename, max_rows=None, only_ids=False):
    # The schema, row count, and metadata all live in the footer,
    # so none of this touches the column data.
    pqt = pq.ParquetFile(filename)
    schema = pqt.schema_arrow
    num_rows = pqt.metadata.num_rows

    # Show file metadata if present
    if schema.metadata:
        print("File Metadata:")
        for key, value in sorted(schema.metadata.items()):
            if isinstance(key, bytes):
                key = key.decode('utf-8')
            if isinstance(value, bytes):
                value = value.decode('utf-8')
            print(f"  {key}: {value}")
        print()

    print("Schema:")
    print(schema)
    print()
    print(f"Rows: {num_rows}   Columns: {pqt.metadata.num_columns}")
    print()

    if only_ids:
        show_ids(filename)
        return

    for i, row in enumerate(read_rows(pqt, max_rows)):
        print(f"--- Record {i} ---")
        for k, v in row.items():
            s = str(v)
            if len(s) > TRUNC:
                s = s[:TRUNC] + f"... ({len(str(v))} chars)"
            print(f"  {k}: {s}")
        print()

    if max_rows is not None and num_rows > max_rows:
        print(f"({num_rows - max_rows} more rows not shown)")


def show_ids(filename):
    """
    Report the row_id values in the file and how many rows each one
    contributed.  Reading the single row_id column leaves the other
    columns on disk, so this stays cheap on large files.

    A row_id appearing in more than one contiguous run means the same
    task was written twice -- log2pqt -a is supposed to refuse that,
    so it is reported as an error.
    """
    from collections import Counter

    column = pq.read_table(filename, columns=["row_id"])
    ids = column.column("row_id").to_pylist()
    counts = Counter(ids)

    print(f"Distinct row_id: {len(counts)}")
    print()
    width = max((len(str(i)) for i in counts), default=0)
    for row_id in sorted(counts):
        print(f"  {row_id:>{width}}  {counts[row_id]} rows")
    print()

    # Rows for one task are written consecutively, so a task written
    # twice shows up as more than one run of its id.
    runs = Counter(a for a, b in zip(ids, [None] + ids) if a != b)
    repeated = sorted(i for i in runs if runs[i] > 1)
    if repeated:
        print(f"ERROR: {len(repeated)} row_id written more than once:")
        for row_id in repeated:
            print(f"  {row_id} appears in {runs[row_id]} separate runs")
    else:
        print("No duplicate row_id")


def read_rows(pqt, max_rows):
    """
    Read at most max_rows records.

    iter_batches() yields one batch at a time, so abandoning the
    generator after the first batch leaves the remaining row groups
    unread -- a file of any size costs the same as its first batch.
    """
    if max_rows is None:
        return pqt.read().to_pylist()
    if max_rows <= 0:
        return []
    for batch in pqt.iter_batches(batch_size=max_rows):
        return batch.to_pylist()
    return []


if __name__ == "__main__":
    main()
