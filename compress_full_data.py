#!/usr/bin/env python3
import glob
import numpy as np
import h5py
import time
from yt.frontends.boxlib.api import AMReXDataset


def main():
    """
    Consolidate all the plot data into a single file.
    """


    p_trans = []
    shelter = []

    # Iterate over all the plt folders
    plts = sorted(glob.glob("plt*"))

    ds = AMReXDataset('plt00000/')
    ad = ds.all_data()

    inds = np.where(np.array(ds.field_list)[:,0] == 'agents')
    agents = np.array(ds.field_list)[inds][:,1]

    inds = np.where(np.array(ds.field_list)[:,0] == 'boxlib')
    boxlib = np.array(ds.field_list)[inds][:,1]

    hf = h5py.File('total.h5', 'w')

    # Initialize the hdf5 file with the arrays.
    for agent in agents:
        data = ad[agent].d
        data = data.reshape(1,data.shape[0])
        hf.create_dataset(agent, data=data, compression="gzip", chunks=True, maxshape=(None,None))

    # Only need to do once.
    for b in boxlib:
        hf.create_dataset(b, data=ad[b].d, compression="gzip")

    # Get the new agents from plt00001
    ds = AMReXDataset('plt00001')
    inds = np.where(np.array(ds.field_list)[:,0] == 'agents')
    agents = np.array(ds.field_list)[inds][:,1]

    for e, plt in enumerate(plts[1:]):

        start = time.time()

        ds = AMReXDataset(plt)
        ad = ds.all_data()

        for agent in agents:
            data = ad[agent].d
            data = data.reshape(1, data.shape[0])
            hf[agent].resize(hf[agent].shape[0] + data.shape[0], axis=0)
            hf[agent][-data.shape[0]:] = data

        end = time.time()
        print(f'{e+1:03} {end-start:.2f} s')

    hf.close()

if __name__ == "__main__":
    main()
