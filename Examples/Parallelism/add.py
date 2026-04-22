#!/usr/bin/env python3

import sys

my_id      = sys.argv[1]
parent_ids = sys.argv[2].split(',')
filenames  = [n + ".out" for n in parent_ids]

result     = sum([int(open(f).readline().strip()) for f in filenames])

with open(my_id + ".out",'w') as out_f:
    print(result,file=out_f)
