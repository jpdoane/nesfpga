#!/usr/bin/python3

import argparse, os
import argparse

def cmp_log(log1file, log2file):
    try:
        log1 = open(log1file, 'r').readlines()
        log2 = open(log2file, 'r').readlines()
        ln=0
        for l1,l2 in zip(log1,log2):
            ln = ln+1
            pc1 = l1.split(' ')[0].lower()
            pc2 = l2.split(' ')[0].lower()
            if pc1 != pc2:
                print("Logs diverge at line %d:  %s vs %s" % (ln, pc1, pc2))
                return 0
        
        return 1
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test if two log files match")
    parser.add_argument("log1file", help="Log file 1")
    parser.add_argument("log2file", help="Log file 2")

    args = parser.parse_args()
    log1file = args.log1file
    log2file = args.log2file

    if cmp_log(log1file, log2file):
        print("Logs Match")
