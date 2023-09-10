#!/usr/bin/python3

import argparse, os
import argparse

def parse_token(strlist, token):
    toklen = len(token)
    for t in strlist:
        if t[0:toklen] == token:
            val = t[toklen:]
            return val
    print("token %s not found in string %s" % (token, strlist))
    return None

def cmp_log(log1file, log2file):
    try:
        log1 = open(log1file, 'r').readlines()
        log2 = open(log2file, 'r').readlines()
        ln=0
        for l1,l2 in zip(log1,log2):
            ll1 = l1.lower().split(' ')
            ll2 = l2.lower().split(' ')
            ln = ln+1
            match = 1
            if (ll1[0] != ll2[0]) | (ll1[1] != ll2[1]):
                match = 0
            # for t in ("a:","x:","y:","s:", "p:", "v:", "h:", "cycle:"):
            for t in ("a:","x:","y:","s:", "p:"):
                if parse_token(ll1, t) != parse_token(ll2, t):
                    match = 0
            if match != 1:
                print("Logs diverge at line %d" % ln)
                print("%s:%d      %s" % (log1file, ln ,l1))
                print("%s:%d      %s" % (log2file, ln ,l2))
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
