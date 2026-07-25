#!/usr/bin/env python3
"""
Validate a log2pqt output Parquet file against:
  1. the reference format (part-000000.parquet), and
  2. the source JSON-lines log it was generated from.

Usage:
    python3 validate_pqt.py <output.parquet> <source.log> [reference.parquet]

Checks:
  - valid Parquet magic bytes
  - readable by pyarrow
  - schema (column names + types) matches the reference exactly
  - row count == sum of data rows across all records' output_dat tables
  - spot-check: exploded values match the source output_dat text
"""

import json
import sys

REFERENCE_DEFAULT = "part-000000.parquet"


def check_magic(path):
    with open(path, "rb") as f:
        data = f.read()
    ok = data[:4] == b"PAR1" and data[-4:] == b"PAR1"
    print(f"[magic]  start={data[:4]!r} end={data[-4:]!r} size={len(data)} -> {'OK' if ok else 'FAIL'}")
    return ok


def load_log(log_path):
    """Parse the (slightly malformed) results log.

    Object values contain literal newlines, which JSON forbids, and
    objects may be pretty-printed with whitespace padding between
    them. Scan char by char, escaping control chars inside strings,
    and yield each top-level object -- mirroring the Java reader.
    """
    with open(log_path) as f:
        data = f.read()

    records = []
    obj = []
    in_string = False
    escaped = False
    depth = 0

    for c in data:
        if depth == 0 and not in_string and c != "{":
            continue

        if in_string:
            if escaped:
                obj.append(c)
                escaped = False
            elif c == "\\":
                obj.append(c)
                escaped = True
            elif c == '"':
                obj.append(c)
                in_string = False
            elif c == "\n":
                obj.append("\\n")
            elif c == "\r":
                obj.append("\\r")
            elif c == "\t":
                obj.append("\\t")
            else:
                obj.append(c)
            continue

        if c == '"':
            obj.append(c)
            in_string = True
            continue
        if c == "{":
            depth += 1
        obj.append(c)
        if c == "}":
            depth -= 1
            if depth == 0:
                records.append(json.loads("".join(obj)))
                obj = []

    return records


def count_data_rows(records):
    """Total non-header, non-empty rows across all output_dat tables."""
    total = 0
    for rec in records:
        od = rec.get("output_dat", "")
        lines = [ln for ln in od.split("\n") if ln.strip()]
        if len(lines) > 1:
            total += len(lines) - 1  # minus header
    return total


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 validate_pqt.py <output.parquet> <source.log> [reference.parquet]")
        sys.exit(2)

    out_path = sys.argv[1]
    log_path = sys.argv[2]
    ref_path = sys.argv[3] if len(sys.argv) > 3 else REFERENCE_DEFAULT

    failures = 0

    if not check_magic(out_path):
        failures += 1

    try:
        import pyarrow.parquet as pq
    except ImportError:
        print("[read]   pyarrow not installed; magic-byte check only.")
        print("         Run: pip install pyarrow")
        sys.exit(0 if failures == 0 else 1)

    out = pq.read_table(out_path)
    print(f"[read]   {out.num_rows} rows, {out.num_columns} columns")

    # 1. schema matches reference
    try:
        ref = pq.read_table(ref_path)
        out_schema = [(f.name, str(f.type)) for f in out.schema]
        ref_schema = [(f.name, str(f.type)) for f in ref.schema]
        if out_schema == ref_schema:
            print(f"[schema] matches reference {ref_path} -> OK")
        else:
            print(f"[schema] MISMATCH vs {ref_path}:")
            print(f"         output   : {out_schema}")
            print(f"         reference: {ref_schema}")
            failures += 1
    except FileNotFoundError:
        print(f"[schema] reference {ref_path} not found -> SKIP")

    # 2. row count == exploded data rows in the log
    log_records = load_log(log_path)
    expected = count_data_rows(log_records)
    if out.num_rows == expected:
        print(f"[rows]   {out.num_rows} == exploded data rows from log -> OK")
    else:
        print(f"[rows]   MISMATCH: parquet={out.num_rows} expected={expected} -> FAIL")
        failures += 1

    # 3. spot-check first record's first data row against the parquet
    if log_records:
        rows = out.to_pylist()
        ok = spot_check(log_records[0], rows, out.column_names)
        if ok:
            print("[value]  first data row matches source output_dat -> OK")
        else:
            print("[value]  first data row MISMATCH -> FAIL")
            failures += 1

    print()
    if failures == 0:
        print("RESULT: PASS")
        sys.exit(0)
    print(f"RESULT: FAIL ({failures} check(s) failed)")
    sys.exit(1)


def spot_check(record, rows, columns):
    """Verify the first exploded row against record.output_dat line 1."""
    od = record["output_dat"]
    lines = [ln for ln in od.split("\n") if ln.strip()]
    if len(lines) < 2:
        return True
    header = lines[0].split()
    first = lines[1].split()
    src = {header[i].replace("/", "_"): first[i] for i in range(len(header))}

    row = rows[0]
    # row_id comes from task_id; seed from seed
    if row["row_id"] != record["task_id"]:
        print(f"         row_id {row['row_id']} != task_id {record['task_id']}")
        return False
    if row["seed"] != record["seed"]:
        print(f"         seed {row['seed']} != {record['seed']}")
        return False
    for col in columns:
        if col in ("row_id", "seed"):
            continue
        if col not in src:
            continue
        want = float(src[col])
        got = float(row[col])
        if abs(want - got) > 1e-6:
            print(f"         col {col}: parquet={got} != source={want}")
            return False
    return True


if __name__ == "__main__":
    main()
