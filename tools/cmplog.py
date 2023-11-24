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

def cmp_log(log1file, log2file, ignorepcs, matchregs):
    try:
        log1 = open(log1file, 'r').readlines()
        log2 = open(log2file, 'r').readlines()
        n1 = 0
        n2 = 0
        while True:
            if n1>=len(log1) or n2>=len(log2):
                return True #reached the end of one of the logs without mismatch, return True

            #parse line into tokens
            l1 = log1[n1].lower().strip().split(' ')
            l2 = log2[n2].lower().strip().split(' ')

            # ignore certain pcs
            if l1[0] in ignorepcs:
                n1 += 1
                continue
            if l2[0] in ignorepcs:
                n2 += 1
                continue

            match = (l1[0] == l2[0]) and (l1[1] == l2[1])
            if match:
                for t in matchregs:
                    if parse_token(l1, t) != parse_token(l2, t):
                        print("token %s does not match" % t)
                        match = False
                        
            if not match:
                print("Logs diverge:")
                print("%s:%d\n\t%s" % (log1file, n1+1 ,log1[n1]))
                print("%s:%d\n\t%s" % (log2file, n2+1 ,log2[n2]))
                return False
        
            n1 += 1
            n2 += 1
            
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test if two log files match")
    parser.add_argument("log1file", help="Log file 1")
    parser.add_argument("log2file", help="Log file 2")
    parser.add_argument('-i', '--ignorepcs', nargs='?', help="Ignore these PC")
    parser.add_argument('-m', '--matchregs', nargs='?', help="Match these registers")

    args = parser.parse_args()
    log1file = args.log1file
    log2file = args.log2file
    if args.ignorepcs:
        ignorepcs = args.ignorepcs.lower().strip().split(',')
    else:
        ignorepcs = []
    if args.matchregs:
        matchregs = [m+":" for m in args.matchregs.lower().strip().split(',')]

    else:
        matchregs = []

    if cmp_log(log1file, log2file, ignorepcs, matchregs):
        print("Logs Match")
