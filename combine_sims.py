#!/usr/bin/env python3
import os
import sys
import glob
import h5py
import argparse
import time
from mpi4py import MPI


def main(data_dir, merlin_paths, outfile):

    comm = MPI.COMM_WORLD
    size = comm.Get_size()
    rank = comm.Get_rank()

    print(f'Size: {size}, Rank: {rank}\n')

    loc = ['FIPS', 'Tract', 'comm', 'particle_nborhood', 'particle_work_nborhood']
    data = ['particle_infection_prob', 'particle_status']

    sub_paths = merlin_paths.split()

    data_dir = os.path.abspath(data_dir)

    all_sims = h5py.File(f'{data_dir}/seed.h5', 'w', driver="mpio", comm=comm)

    group_dict = {}
    for d in data:
        group_dict[d] = all_sims.create_group(d)

    # Merlin paths are given in order of sample ID
    for i, p in enumerate(sub_paths):
        path = f'{data_dir}/{p}/plt.h5'
        start = time.time()
        print(f"Loading file: {path}")
        if os.path.exists(path):
            hf = h5py.File(path, 'r', driver="mpio", comm=comm)
            end = time.time()
            print(end-start)
        else:
            sys.exit(f'File not found at {path}.')

        # Add data to all_sims
        for d in data:
            group_dict[d].create_dataset(f'sim_{i:03}', data = hf.get(d), compression='gzip')

        end = time.time()
        print(f'Took {end-start} seconds')

    for l in loc:
        all_sims.create_dataset(l, data = hf.get(l), compression='gzip')

    all_sims.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-data", help = "The home directory of the runs of the current seed")
    parser.add_argument("-runs", help="Merlin sample paths given by Merlin")
    parser.add_argument("-outfile", nargs="*", help = "The path of output file")
    
    args = parser.parse_args()

    main(args.data, args.runs, args.outfile)
