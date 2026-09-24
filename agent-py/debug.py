
"""
DEBUG PY
Debugging functions
"""

def report_tmp(idx):
    import os
    user =     os.getenv("USER")
    rank = int(os.getenv("ADLB_RANK_SELF"))
    work_dir = f"/tmp/{user}/exaepi"
    files = os.listdir(work_dir)
    print("rank %3i: idx %3i: %s" % (rank, idx, str(files)), flush=True)
    # Return a string to Swift/T:
    return str(True)
