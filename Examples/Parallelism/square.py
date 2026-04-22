#!/usr/bin/env python3

import sys

my_id  = sys.argv[1]
number = int(sys.argv[2])

with open(my_id + ".out",'w') as out_f:
    print(number * number,file=out_f)

