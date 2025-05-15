#!/usr/bin/env python3
import argparse

def main(
    seed: int, 
    trans: float, 
    compliance: float, 
    shelter_day: int, 
    outfile: str
    ):

    f = open(f'{outfile}/inputs', 'w')

    f.write(f"""agent.max_grid_size = 16
agent.ic_type = "census"
agent.census_filename = "./BayArea.dat"
agent.workerflow_filename = "./BayArea-wf.bin"
agent.case_filename = "./July4.cases"

agent.nsteps = 180
agent.seed = {int(seed)}
agent.plot_int = 1
agent.random_travel_int = 1
agent.aggregated_diag_int = -1
agent.aggregated_diag_prefix = "cases"
agent.initial_case_type = "random"
agent.num_initial_cases = 10
agent.shelter_compliance = {compliance}
agent.shelter_start = {int(shelter_day)}
agent.shelter_length = 30
agent.mean_immune_time = 180
agent.immune_time_spread = 60
agent.symptomatic_withdraw = 1
agent.symptomatic_withdraw_compliance = 0.90

contact.pSC = 0.2
contact.pCO = 1.45
contact.pNH = 1.45
contact.pWO = 0.5
contact.pFA = 1.0
contact.pBAR = -1.

disease.nstrain = 1
disease.p_trans = {trans}
disease.p_asymp = 0.20
disease.reduced_inf = 0.75
disease.symptomdev_length_mean = 3.0
""")

    f.close()



if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-trans", help="Probability of transmission")
    parser.add_argument("-compliance", help="Percentage in decimal of compliance")
    parser.add_argument("-shelter_day", help="Day shelter-in-place starts")
    parser.add_argument("-seed", help="Seed for the random number generator")
    parser.add_argument("-outfile", help="Location to write the file")

    args = parser.parse_args()

    main(int(float(args.seed)), float(args.trans), float(args.compliance), int(float(args.shelter_day)), str(args.outfile))
