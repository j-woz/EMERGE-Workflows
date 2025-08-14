#!/usr/bin/env python3
import os
import sys
import glob
import h5py
import argparse
import time
from mpi4py import MPI


def main():

    comm = MPI.COMM_WORLD
    size = comm.Get_size()
    rank = comm.Get_rank()

    print(f'Size: {size}, Rank: {rank}\n')

    loc = ['FIPS', 'Tract', 'comm', 'particle_nborhood', 'particle_work_nborhood']
    data = ['particle_infection_prob', 'particle_status']

    seeds = sorted(glob.glob("SEED*"))

    for seed in seeds:

        os.chdir(seed)
        print(seed.lower())

        all_sims = h5py.File(f'{seed.lower()}.h5', 'w', libver="latest", driver="mpio", comm=comm)

        sims = sorted(glob.glob("*/"))

        group_dict = {}
        for d in data:
            group_dict[d] = all_sims.create_group(d)
    
        # Merlin paths are given in order of sample ID
        for i, p in enumerate(sims):
            path = f'{p}/plt.h5'
            start = time.time()
            print(f"Loading file: {path}")
            if os.path.exists(path):
                hf = h5py.File(path, 'r')
                end = time.time()
                print(end-start)
            else:
                sys.exit(f'File not found at {path}.')
    
            # Add data to all_sims
            for d in data:
                group_dict[d].create_dataset(f'sim_{i:03}', data = hf.get(d))
    
            end = time.time()
            print(f'Took {end-start} seconds')
            hf.close()
    
        for l in loc:
            all_sims.create_dataset(l, data = hf.get(l), compression='gzip')
    
        all_sims.close()


if __name__ == "__main__":
    main()
