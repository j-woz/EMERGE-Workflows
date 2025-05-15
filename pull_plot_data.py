#!/usr/bin/env python3
import os
import glob
import numpy as np
import h5py
import time
import argparse
from yt.frontends.boxlib.api import AMReXDataset


def main(d, outfile):
    """
    Consolidate all the plot data into a single file.
    """

    loc = ['FIPS', 'Tract', 'comm', 'particle_nborhood', 'particle_work_nborhood']
    data = ['particle_infection_prob', 'particle_status']

    hf = h5py.File(f'{outfile}/plt.h5', 'w')

    # Iterate over all the plt folders
    plts = sorted(glob.glob(f"{d}/plt*/"))

    for e, plt in enumerate(plts):

        start = time.time()

        ds = AMReXDataset(plt)
        ad = ds.all_data()

        if e == 0:
            for l in loc:
                hf.create_dataset(l, data=ad[l].d, compression="gzip")

            for d in data:
                temp = ad[d].d
                temp = temp.reshape(1, temp.shape[0])
                hf.create_dataset(d, data=temp, compression="gzip", chunks=True, maxshape=(None, None))

        else:
            for d in data:
                temp = ad[d].d
                temp = temp.reshape(1, temp.shape[0])
                hf[d].resize(hf[d].shape[0] + temp.shape[0], axis=0)
                hf[d][-temp.shape[0]:] = temp

        ds.close()

        end = time.time()

        print(f'{e:3}, {end-start:.2f} seconds')

    hf.close()

    # Write finished file for merlin
    os.system(f'touch {outfile}/PARSE_FINISHED')

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-dir', default='./', help='Directory where the plt files are located.')
    parser.add_argument('-outfile', default='./', help='Directory to write the hdf5 file.')

    args = parser.parse_args()

    main(args.dir, args.outfile)
