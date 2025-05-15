#!/usr/bin/env python3
import ast
import sys
import argparse
import numpy as np


def main(
    shelter_day: int,
    shelter_num_days: int,
    p_trans: list,
    compliance: list,
    outfile:str
    ):
    """
    This script will take the inputs for generating a sample input for a merlin run of ExaEpi.
    """

    array = []
    p_trans = np.array(ast.literal_eval(p_trans)).astype('float')
    compliance = np.array(ast.literal_eval(compliance)).astype('float')

    for day in range(shelter_day, shelter_day+shelter_num_days):
        for p in p_trans:
            for c in compliance:
                array.append([day, p, c])

    output = np.array(array)

    np.save(outfile, output)

    print(output)

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("-shelter_day", help="Starting day of shelter in place.")
    parser.add_argument("-shelter_num_days", help="Number of days to shelter.")
    parser.add_argument("-p_trans", help="String of p_trans values. Ex. '[0.8,0.95]'.")
    parser.add_argument("-compliance", help="String of compliance values. Ex. '[0.8,0.95]'.")
    parser.add_argument("-outfile", help = "Output filename to save")

    args = parser.parse_args()

    main(int(args.shelter_day), int(args.shelter_num_days), args.p_trans, args.compliance, args.outfile)
